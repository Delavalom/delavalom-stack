// Run against the engine: `claude plugin test .`
import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On, SessionRateLimit } from 'claude-code'

const NOW = Date.parse('2026-10-12T10:00:00Z')
const HOUR = 3_600_000
const later = (ms: number) => new Date(NOW + ms).toISOString()

const SUBSCRIPTION: SessionRateLimit[] = [
  { kind: 'five_hour', percentUsed: 40, resetsAt: later(3 * HOUR) },
  { kind: 'seven_day', percentUsed: 82, resetsAt: later(50 * HOUR) }
]
// An Enterprise seat's usage, as /api/oauth/usage answers it: no windows, a monthly budget.
const SEAT = { five_hour: null, seven_day: null, extra_usage: { is_enabled: true, monthly_limit: 55000, used_credits: 17288, utilization: 31.43, currency: 'USD' } }

/** The engine beneath the plugin. `account` is what the usage endpoint returns; null fails the request. */
function engine (on: On, rateLimits: SessionRateLimit[], account: object | null = { extra_usage: null }) {
  const clock = mock.clock(on, { now: NOW })
  const store: Record<string, unknown> = {}
  const requests: string[] = []
  const toasts: string[] = []
  on('ui.toast', ($, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('store.get', ($, e) => ({ value: store[e.key] }))
  on('store.set', ($, e) => {
    store[e.key] = JSON.parse(JSON.stringify(e.value))
    return { value: undefined }
  })
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.usage', () => ({ value: { startedAt: NOW, context: { window: 200_000 }, rateLimits } as never }))
  on('session.measure', ($, e) => ({ changed: e.changed }))
  on('session.authorize', () => ({ value: { handle: 'h', kind: 'bearer' } }))
  on('http.fetch', ($, e) => {
    requests.push(e.url)
    return { value: account === null ? { status: 500, ok: false, headers: {}, text: '' } : { status: 200, ok: true, headers: {}, text: JSON.stringify(account) } }
  })
  on('ui.render', ($, e) => {
    const { Box } = $.ui.resolve(e)
    return e.props.modes.length > 0 ? <Box key="modes" /> : ({ type: 'engine', ref: 0 } as const)
  })
  return { clock, store, requests, toasts }
}

const start = ($: Engine) => $.session.start({ cwd: '/p', surface: 'terminal', isInteractive: true })
const measure = ($: Engine, rateLimits: SessionRateLimit[] = []) =>
  $.session.measure({ context: { window: 200_000 }, rateLimits, changed: ['rateLimits'] } as never)
const texts = async ($: Engine, columns = 120, modes: string[] = []) => {
  const ui = await $.ui.mount({ plugin: 'sub-meter', surface: 'terminal', component: 'SessionMode', props: { modes }, viewport: { columns, rows: 30 } })
  return (await ui.findAll({ type: 'Text' })).map(text => text.text)
}

test("shows an Enterprise seat's monthly budget, resetting on the 1st", async ($, on) => {
  const w = engine(on, [], SEAT)
  await start($)
  expect(w.requests).toEqual(['https://api.anthropic.com/api/oauth/usage'])
  expect(await texts($)).toEqual(['budget ', '███', '░░░░░░░ ', '31%', ' · resets 19d'])
  expect(w.store.reading).toEqual({ label: 'budget', percent: 31.4, resetsAt: '2026-11-01T00:00:00.000Z' })
})

test('asks for the budget at most every five minutes', async ($, on) => {
  const w = engine(on, [], SEAT)
  await start($)
  await measure($)
  expect(w.requests.length).toBe(1)
  await w.clock.advance(5 * 60_000)
  await measure($)
  expect(w.requests.length).toBe(2)
})

test("on a subscription it shows the tightest window and never asks for a budget", async ($, on) => {
  const w = engine(on, SUBSCRIPTION, SEAT)
  await start($)
  expect(w.requests).toEqual([])
  expect(await texts($)).toEqual(['week ', '████████', '░░ ', '82%', ' · resets 2d'])
})

test('a new measurement replaces the reading and turns red from 90%', async ($, on) => {
  engine(on, SUBSCRIPTION)
  await start($)
  await measure($, [{ kind: 'five_hour', percentUsed: 93, resetsAt: later(HOUR) }])
  const ui = await $.ui.mount({ plugin: 'sub-meter', surface: 'terminal', component: 'SessionMode', props: { modes: [] }, viewport: { columns: 120, rows: 30 } })
  expect((await ui.find({ type: 'Text', text: '93%' }))?.props.color).toBe('error')
})

test('the last reading shows at the next start before anything is measured', async ($, on) => {
  const w = engine(on, [], null)
  w.store.reading = { label: 'budget', percent: 50, resetsAt: '2026-11-01T00:00:00.000Z' }
  await start($)
  expect(await texts($)).toContain('50%')
})

test('a narrow terminal drops the bar and reset, a very narrow one the meter', async ($, on) => {
  engine(on, [], SEAT)
  await start($)
  expect(await texts($, 80)).toEqual(['budget ', '31%'])
  expect(await texts($, 60)).toEqual([])
})

test("keeps the engine's mode labels after the meter", async ($, on) => {
  engine(on, [], SEAT)
  await start($)
  const ui = await $.ui.mount({ plugin: 'sub-meter', surface: 'terminal', component: 'SessionMode', props: { modes: ['focus'] }, viewport: { columns: 120, rows: 30 } })
  expect((await ui.drawn()).children?.at(-1)).toMatchObject({ props: { key: 'modes' } })
})

for (const [name, account] of [['is off', { extra_usage: { is_enabled: false } }], ['has no limit', { extra_usage: { is_enabled: true, utilization: null } }], ['request fails', null]] as const) {
  test(`shows nothing when the budget ${name}`, async ($, on) => {
    engine(on, [], account)
    await start($)
    expect(await texts($)).toEqual([])
  })
}

test('warns once as usage climbs past 75% and again past 90%', async ($, on) => {
  const w = engine(on, [{ kind: 'seven_day', percentUsed: 60, resetsAt: later(50 * HOUR) }])
  await start($)
  expect(w.toasts).toEqual([])
  await measure($, [{ kind: 'seven_day', percentUsed: 76, resetsAt: later(50 * HOUR) }])
  await measure($, [{ kind: 'seven_day', percentUsed: 80, resetsAt: later(50 * HOUR) }])
  await measure($, [{ kind: 'seven_day', percentUsed: 91, resetsAt: later(50 * HOUR) }])
  expect(w.toasts).toEqual(['week 76% used · resets 2d', 'week 91% used · resets 2d'])
})

test('a reading already past the line at the next start does not warn again', async ($, on) => {
  const w = engine(on, [], { extra_usage: { is_enabled: true, utilization: 80 } })
  w.store.reading = { label: 'budget', percent: 78, resetsAt: '2026-11-01T00:00:00.000Z' }
  await start($)
  expect(w.toasts).toEqual([])
})

test('a jump straight past 90% warns once, at 90', async ($, on) => {
  const w = engine(on, [], { extra_usage: { is_enabled: true, utilization: 95 } })
  await start($)
  expect(w.toasts).toEqual(['budget 95% used · resets 19d'])
})
