# Sub Meter

A Claude Code mod: your subscription usage, always at the bottom right, on the same line as the permission mode.

```text
⏵⏵ auto mode on                                   5h ━━━━━━──── 58% ↻ 2h 10m
```

Every 8 seconds it switches between the **5-hour** window and the **weekly** one (change it in `/config`, `rotateSeconds`). The bar turns yellow from 75% and red from 90%. After it, behind ↻, the time until that window resets.

Where the footer is short it fits the row instead of breaking to a second line: first the bar goes, then the reset time, and in a very narrow terminal the meter itself. Beside [Narrator](../narrator), the meter shrinks first, then the switch.

```text
⏵⏵ auto mode on ·      5h 58% ↻ 2h 10m · ⏵ narrator on
⏵⏵ auto mode on ·           5h 58% · ⏵ narrator
```

On a seat with a monthly spend limit (Enterprise, a Claude gateway) Claude Code reports a third window, `spend_limit`, and the meter shows it as **budget**, in turn with the others; past the limit the percent goes over 100 and the bar stays full and red.

On an Enterprise or Team seat signed in with claude.ai, Claude Code reports no windows at all; there the meter reads the seat's monthly budget from the account's usage (what `/usage` shows) and shows it as **budget**, with the time until the 1st of next month, when it resets:

```text
⏵⏵ auto mode on                               budget ━━━─────── 31% ↻ 11d 14h
``` Off a subscription or a spend limit (API key billing) there is nothing to show, so the footer stays as it is.

While it is on, it also drops the `(shift+tab to cycle)` hint after the permission mode and `esc to interrupt` while Claude works, to leave room for the meter. Turn either off in `/config` (`hideCycleHint`, `hideInterruptHint`).

## Install

```text
/plugin marketplace add midudev/better-claude
/plugin install sub-meter@better-claude
```

## How it works

One hooks module ([`hooks/register.tsx`](hooks/register.tsx)):

- `session.measure` hands it the rate-limit windows after each response (`five_hour`, `seven_day`, `spend_limit`); `$.session.usage()` gives the first reading at start.
- Where neither gives a window (an Enterprise or Team seat), it asks `https://api.anthropic.com/api/oauth/usage` for `extra_usage`, at start and at most every 5 minutes after a response. The request goes through `$.http.fetch` with `$.session.authorize()`'s handle: the engine sets the session's login on it, and the token never reaches the mod. Off a claude.ai login, without a budget, or with `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` set, it does not ask.
- The last reading is kept in `$.store`, so a new session shows it before its first response.
- A `ui.render` hook on `SessionMode` draws the meter and, after it, what is beneath (the engine's mode labels, another plugin's switch such as Narrator's, which so stays last); `$.clock.every` switches the window.
- The room it has is the terminal's width (`e.viewport.columns`) less the footer's padding, the mode label and the hint, and less what is beneath; the meter takes the widest form that fits.
- A `ui.render` hook on `PromptHint` rewrites the hint line without `(shift+tab to cycle)` and `esc to interrupt`, and notes its width; the engine still draws it, and the mode label before it.

## Development

```bash
claude plugin validate ./sub-meter   # from the repository root
claude plugin test ./sub-meter       # runs hooks/register.test.tsx against the engine
```

MIT © Miguel Ángel Durán (midudev)
