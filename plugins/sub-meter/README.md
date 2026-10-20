# Sub Meter

A Claude Code mod that shows how much of your usage is left, at the bottom right of the prompt footer.

```text
⏵⏵ auto mode on                        budget ███░░░░░░░ 31% · resets 19d
```

- **Enterprise or Team seat** (claude.ai login): your seat's monthly budget, read from the same place `/usage` reads it. It resets on the 1st of the month (UTC).
- **Pro or Max subscription:** whichever window is closest to its limit, the 5-hour or the weekly one.
- **API key or third-party provider:** nothing to show; the footer stays as it is.

The bar turns yellow at 75% and red at 90%, and a toast warns you the first time usage climbs past each line (`budget 91% used · resets 11d`). Below 100 columns the bar and reset time drop; below 70 the meter hides.

## Install

```text
/plugin marketplace add Delavalom/delavalom-stack
/plugin install sub-meter@delavalom-stack
```

## How it works

One hooks module, [`hooks/register.tsx`](hooks/register.tsx):

- On a subscription, the engine reports rate-limit windows at start (`$.session.usage()`) and after each response (`session.measure`). The meter shows the highest one.
- With no windows, it calls `GET https://api.anthropic.com/api/oauth/usage` and reads `extra_usage` (`is_enabled`, `utilization`). It asks at session start, then at most every 5 minutes after a response. The request goes through `$.http.fetch` with the `$.session.authorize()` handle: the engine attaches your login for Anthropic's own host, and the token never reaches the mod. With `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` set, the request is refused and the meter keeps its last reading.
- The last reading is kept in `$.store`, so a new session shows it right away.

## Development

```bash
claude plugin validate ./plugins/sub-meter
claude plugin test ./plugins/sub-meter
```
