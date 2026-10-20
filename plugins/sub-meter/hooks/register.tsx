import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, SessionRateLimit } from 'claude-code'

import type { Reading } from '../types'

const reading = atom({ plugin: 'sub-meter', key: 'reading' } as const, null as Reading | null)

// Enterprise and Team seats get no rate-limit windows from the engine; their monthly budget is in the
// account's usage, the endpoint /usage reads. The engine attaches the login; the token never reaches here.
const USAGE_URL = 'https://api.anthropic.com/api/oauth/usage'
const POLL_MS = 5 * 60_000
const LABELS: Record<string, string> = { five_hour: '5h', seven_day: 'week', spend_limit: 'budget' }
const BAR = 10
// ponytail: fixed breakpoints on terminal width, not a measure of the footer's free room; measure if it clips.
const FULL_COLUMNS = 100
const SHORT_COLUMNS = 70

let polledAt = -Infinity

/** The window closest to its limit, or null when the engine measured none. */
function tightest (limits: readonly SessionRateLimit[]): Reading | null {
  const known = limits.filter(limit => limit.kind in LABELS)
  if (known.length === 0) return null
  const top = known.reduce((a, b) => (b.percentUsed > a.percentUsed ? b : a))
  return { label: LABELS[top.kind], percent: top.percentUsed, resetsAt: top.resetsAt }
}

/** The seat's monthly budget; null off a claude.ai login, without a budget, or when the request fails. */
async function seatBudget ($: EngineInterface): Promise<Reading | null> {
  try {
    const auth = await $.session.authorize()
    if (auth?.kind !== 'bearer') return null
    const res = await $.http.fetch(USAGE_URL, { auth: auth.handle })
    if (!res.ok) return null
    const budget = JSON.parse(res.text)?.extra_usage
    if (!budget?.is_enabled || typeof budget.utilization !== 'number') return null
    const now = new Date(await $.clock.now())
    // ponytail: the API sends no reset for the budget; the 1st of next month, UTC, matches its overage reset.
    const resetsAt = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString()
    return { label: 'budget', percent: Math.round(budget.utilization * 10) / 10, resetsAt }
  } catch {
    return null
  }
}

async function save ($: EngineInterface, next: Reading) {
  await update($, reading, () => next)
  await $.store.set('reading', next)
}

/** Takes the engine's windows when it has any, else asks for the seat's budget at most every POLL_MS. */
async function refresh ($: EngineInterface, limits: readonly SessionRateLimit[]) {
  const window = tightest(limits)
  if (window) return save($, window)
  const now = await $.clock.now()
  if (now - polledAt < POLL_MS) return
  polledAt = now
  const budget = await seatBudget($)
  if (budget) await save($, budget)
}

/** "19d", "4h", "12m": the largest whole unit left. */
function countdown (ms: number) {
  const minutes = Math.max(1, Math.floor(ms / 60_000))
  if (minutes >= 1440) return `${Math.floor(minutes / 1440)}d`
  if (minutes >= 60) return `${Math.floor(minutes / 60)}h`
  return `${minutes}m`
}

const tone = (percent: number) => (percent >= 90 ? 'error' : percent >= 75 ? 'warning' : 'success')

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const stored = await $.store.get('reading')
    if (stored && typeof stored === 'object') await update($, reading, () => stored as Reading)
    await refresh($, (await $.session.usage()).rateLimits)
    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    await refresh($, e.rateLimits)
    return next(e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const beneath = await next(e)
    const shown = await read($, reading)
    const columns = e.surface === 'terminal' ? e.viewport?.columns ?? Infinity : Infinity
    if (!shown || columns < SHORT_COLUMNS) return beneath

    const left = shown.resetsAt === undefined ? undefined : Date.parse(shown.resetsAt) - (await $.clock.now())
    const percent = left !== undefined && left <= 0 ? 0 : shown.percent
    const isFull = columns >= FULL_COLUMNS
    const filled = Math.round((Math.min(Math.max(percent, 0), 100) / 100) * BAR)
    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="row">
        <Text dimColor>{shown.label + ' '}</Text>
        {isFull ? <Text color={tone(percent)}>{'█'.repeat(filled)}</Text> : null}
        {isFull ? <Text dimColor>{'░'.repeat(BAR - filled) + ' '}</Text> : null}
        <Text color={tone(percent)}>{`${Math.round(percent)}%`}</Text>
        {isFull && left !== undefined && left > 0 ? <Text dimColor>{` · resets ${countdown(left)}`}</Text> : null}
        {e.props.modes.length > 0 ? <Text dimColor>{'  '}</Text> : null}
        {beneath}
      </Box>
    )
  })
}
