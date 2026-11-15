---
name: craft-clone
description: Clone any website, web app, app or game with Craft Anything and make it ours. Use when asked to clone, recreate, rebuild or copy an existing product ("clone app.example.com", "rebuild this site in Next.js", "make our own version of this app"). Runs Craft Anything's study → build → check loop, then rebrands, restructures and re-scores the result. Replaces the old clone-webapp skill.
---

# Clone it with Craft Anything, then make it ours

**Argument:** a URL (or an app/game path) and, optionally, what to build it with.
`/craft-clone app.example.com` → a new project folder named after the target.

[Craft Anything](https://github.com/storytold/craft-anything) (open source, Apache-2.0/MIT) studies
the original with real inspection tools, has a coding agent (your own `claude`) build a new
project, compares the build with the original at three screen widths and refines it. It measures
layout per width, so it beats a hand-made clone on fidelity, especially on phones. This skill
drives it, then does the part it doesn't: turning a copy into **our** product.

## 0. Preflight

```sh
craft-anything-cli doctor          # binary, browser, Claude Code sign-in, MCP self-test
```

Not installed: build it from source (Rust 1.97+).

```sh
git clone https://github.com/storytold/craft-anything && cd craft-anything
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo install --locked --path apps/craft-anything-cli
```

`CARGO_NET_GIT_FETCH_WITH_CLI=true` is needed when git config rewrites `https://github.com/` to SSH
(cargo's built-in git can't use the SSH agent). A cold build takes about 11 minutes.

## 1. Gate: may we, and can we see it?

- **Make it ours, never a fake.** The deliverable is our own product: our name, brand, copy and
  assets. Never ship anything that passes as the original (its name, logo, trademarks, or a login or
  payment page that imitates it). For games: rebuild the mechanics, never the game's name,
  characters, art, music or levels.
- **Clean room is the default and the rule.** It works only from what a visitor sees. Use Deep mode
  (`--deep`: reads code, files, page source) only on targets we own or are allowed to inspect.
- **Behind a login?** Never create accounts or type credentials. Have the person sign in once in a
  window Craft Anything opens (`python3 scripts/ca_mcp.py signin <url>`, see §5); later captures and
  rebuilds of that exact host reuse the saved session. Craft Anything never sees the password.
  Without a sign-in, the study sees only the signed-out state.

## 2. Rebuild

```sh
craft-anything-cli rebuild <url> "<request>" \
  --project-folder <projects-dir>/<name> --clean-room --unattended --rounds 1 \
  --format jsonl > <projects-dir>/<name>.run.jsonl 2>&1
```

- **Request:** say the scope and the stack, matching the original's stack when known:
  "Recreate this site's landing page (/ only) as a Next.js + Tailwind app". `--build-with`
  (unity, unreal, godot, rust, or a stack's full name) pins it for new projects.
- **`--unattended`** answers questions with the first choice and refuses approvals. Use it inside an
  agent session (no terminal to answer in). Its fixed build commands (`npm install`,
  `npm run build`, `cargo build`…) still run. Without it, the person answers in the terminal.
- **Budget:** the builder is the person's own Claude Code plan, and a rebuild burns it fast (one
  landing page used the rest of a 5-hour window in 21 minutes). Start with `--rounds 1`, look, then add
  rounds. If it stops (`status: needs_you` in `craft.json`), resume after the reset:
  `craft-anything-cli rebuild --continue-in <folder> --resume x`.
- Run it in the background and read the `.run.jsonl` for progress: `[Study]`, `[Build]`, and
  "about N% like the original, X of Y claims hold" after each check.
- The study may also photograph linked pages (it crawled `/docs` when asked for `/` only). That only
  costs time; the request scopes the build.

Project folder layout: `craft.json` (request, status, history), `capture/` (the original, per
width), `app/` (the build), `checks/round-N/` (the build, per width), `investigation.cany/`.

## 3. Look before trusting the number

Its own percentage is a claim check, not a pixel score. Score both sides on the same yardstick:

```sh
python3 scripts/ca_mcp.py score <folder>/capture <folder>/checks/round-<N>
```

That prints `layout_similarity` and `perceptual_similarity` (0..1, SSIM) per width. Then open the
build and **look at every route at every width**. A score can't see wrong copy or a broken
interaction. Benchmark from the first run: 0.95 / 0.94 / 0.71 perceptual at 1440 / 768 / 390.

## 4. Make it ours

Craft Anything copies what it sees, including the original's bugs (it reproduced leaked markup in a
code sample). Then:

1. **Rebrand.** Our product name, logo, colours, fonts and copy. Strip the original's trademarks,
   people, testimonials, pricing and legal text. Swap its images for ours or placeholders.
2. **Fix what it copied.** Visible bugs, dead links, links pointing back at the original's domain.
3. **Restructure for maintenance.** Its output is often one big page file. Split it into sections
   and components, move copy into one content module, and add lint (`next lint`/ESLint) and a typecheck
   script. For apps, put data behind one seam (`lib/data/`) so a real backend drops in later.
4. **Wire the real thing.** Forms, auth and data that were facades now point at our backend, or
   are clearly marked dummy in the README.
5. **Verify again.** Typecheck, lint and build clean. Run §3's score on the rebranded build to catch
   layout regressions, then look at every route at every width once more.

## 5. `scripts/ca_mcp.py`

Each CLI call starts and closes its own browser, so open + capture + compare must run in **one** MCP
session. The script drives `craft-anything-cli mcp` over stdio:

```sh
python3 scripts/ca_mcp.py signin  <url>                 # person signs in, closes the window
python3 scripts/ca_mcp.py capture <url> <new-out-dir>   # screenshots at 1440/768/390 + tokens
python3 scripts/ca_mcp.py score   <orig-dir> <build-dir>  # pixel/SSIM compare per width
```

Capture a running local build (`pnpm start`, a static server on `out/`) and score it against the
project's `capture/`.

## 6. Land it

- Git: init or branch, commit with a message saying what was cloned and how it was made ours.
- README: what it is, how to run it, routes, what is dummy, and "Built from a Craft Anything rebuild
  of <url>, then rebranded."
- Report: score per width, routes opened and looked at, what was rebranded, what's still dummy,
  and anything not reached (signed-out screens, flows not walked). Never call a route faithful if
  you didn't open it.
