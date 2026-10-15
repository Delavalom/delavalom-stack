# Delavalom Stack — Portable Claude Code Skill Set

The 36 skills I actually use, vendored into one repo so they install anywhere with one command. Plus a mise/starship/zsh shell setup.

## Quick Start

```bash
git clone https://github.com/delavalom/delavalom-stack.git
cd delavalom-stack
bash install.sh --full
```

## The Skills

### Design & architecture

| Skill | What it does |
|-------|--------------|
| `architect` | Sketch types, signatures, and module boundaries before writing code |
| `how` | Explain how a subsystem works; placement, ownership, and layering questions |
| `why` | Recover design rationale from source control, issues, docs, chat, observability |
| `blast-radius` | Find what a change breaks outside the diff, then prove it by running real code |

### Engineering principles

| Skill | What it does |
|-------|--------------|
| `principle-model-the-domain` | Encode the domain in a structure, not scattered conditionals |
| `principle-boundary-discipline` | Concentrate validation at boundaries; keep business logic pure |
| `principle-make-operations-idempotent` | Converge to the same state across crashes and retries |
| `principle-prove-it-works` | Verify against the real artifact before declaring done |
| `principle-no-cope` | If a workaround needs a paragraph to justify it, the code is wrong. Auto-triggers |
| `principle-fix-root-causes` | Trace symptoms to the cause; no nil-check guards that silence crashes |
| `principle-laziness-protocol` | Bias toward deletion and the smallest change that solves the problem |
| `principle-subtract-before-you-add` | Remove before extending |
| `principle-exhaust-the-design-space` | Design it twice before committing to a shape |
| `principle-redesign-from-first-principles` | Rebuild as if the new constraints were day-one assumptions |
| `principle-foundational-thinking` | Scaffold the contract first, fill in bodies after |
| `principle-outcome-oriented-execution` | Optimize for the outcome, not for looking busy |
| `principle-encode-lessons-in-structure` | Put the lesson in the code or the gate, not in a rule nobody reads |
| `principle-separate-before-serializing-shared-state` | Give parallel work its own space instead of a lock |
| `principle-minimize-reader-load` | Write for the next reader's working memory |
| `principle-guard-the-context-window` | Treat context as the scarce resource it is |

### Verification & review

The merciless-verification core. `run-loop` is the one that runs constantly; the rest back it up.

| Skill | What it does |
|-------|--------------|
| `run-loop` | Failing check first, then loop against real terminal output until the gate is truly green. Auto-triggers |
| `adversarial-review` | Review a diff with models that never saw the reasoning and didn't write it |
| `harden-the-loop` | Audit and fix the repo's gate so an agent can verify itself: fast, loud, honest |
| `arena` | Fan out N candidates at one task, pick a base, graft the best of the losers in |
| `interrogate` | Adversarial pressure on a design or plan before it becomes code |
| `create-verification-skill` | Generate a project-local skill that drives the real app like a user |
| `maintain-verification-skill` | Keep that skill's feature map honest as the app changes |
| `tdd` | Make the bug executable before fixing it, when the test path is cheap |
| `show-me-your-work` | Keep a reviewable TSV decision trail for long or unattended runs |

### Writing

| Skill | What it does |
|-------|--------------|
| `technical-writing` | Diátaxis structure, Google style, STE instructions, Global English |
| `unslop` | Cut AI tells from any writing |
| `bro` | Restate the last message in plain language, no jargon |

### Frontend & infrastructure

| Skill | What it does |
|-------|--------------|
| `no-use-effect` | Always active; never write `useEffect` directly in React or React Native |
| `clone-webapp` | Clone a live web app's frontend into a Next.js + Tailwind copy |
| `use-railway` | Railway projects, services, deployments, environments, troubleshooting |
| `diagram-design` | Branded architecture, flow, and data diagrams as standalone HTML/SVG/PNG |

### Demo & launch videos

Turn code and a live app into a shareable video. `brag` or `app-demo-video` drives the run; the rest are the tools they call.

| Skill | What it does |
|-------|--------------|
| `brag` / `brag-slim` | Launch video from a project or URL: angle, storyboard, music, poster, share copy. On Opus 5.5 `brag` hands off to `brag-slim` |
| `app-demo-video` | Record the real app as 1080p footage (Playwright + Chrome screencast, injected cursor), then cut it into a time-driven composition with push-ins, captions, synced SFX and music |
| `product-launch-video` | Narrated marketing video from a site or product URL |
| `pr-to-video` | Explain a pull request as a short video |
| `general-video` / `faceless-explainer` | Custom and explainer videos without product capture |
| `motion-graphics` | Short, unnarrated motion pieces: kinetic type, stats, logo stings, lower thirds |
| `music-to-video` / `talking-head-recut` / `embedded-captions` | Beat-synced edits, overlays on talking-head footage, burned-in captions |
| `slideshow` | Presentation and pitch decks rendered as video |
| `hyperframes` + `hyperframes-core`, `-animation`, `-keyframes`, `-creative`, `-audio`, `-cli`, `-registry`, `-studio` | HTML-to-video engine: composition contract, motion, camera moves, mixing, lint/check/render |
| `remotion-to-hyperframes` | Port an existing Remotion project |
| `motion-design` | Timing, easing and choreography rules for any animation |
| `media-use` | Source or generate images, icons, music, voice and captions |
| `gsap-*` | GSAP timelines, plugins and performance |

The flow that made the ToolDB launch video: `brag-slim` for the story → `app-demo-video` to record and cut real footage → `motion-design` for timing → share copy written in your voice through the Kleo MCP (`claude mcp add --scope user --transport http kleo https://app.kleo.so/api/mcp/mcp`).

## Installation Modes

```bash
bash install.sh                          # Full: skills + context + shell (default)
bash install.sh --skills                 # Skills only, to ~/.claude/skills/
bash install.sh --shell                  # Shell only: mise + runtimes, starship, zsh plugins
bash install.sh --shell --skip-deps      # Shell configs only, install no packages
bash install.sh --project /path/to/app   # Copy the stack into another project
bash install.sh --project                # Copy the stack into the current directory
bash install.sh --full --skip-shell      # Full install, no shell configuration
bash install.sh --dry-run                # Preview without changing anything
bash install.sh --uninstall              # Remove installed skills + .zshrc line
```

Installing over an existing `~/.claude/skills/<name>` backs it up to `~/.claude/backups/delavalom-stack-<timestamp>/` first, unless it's already identical.

## Shell Configuration

- **mise** — one tool manager for all runtimes (node, python, go, rust, bun, java). Replaces nvm, pyenv, rustup with a single `mise.toml`.
- **starship** — gruvbox dark prompt with polyglot language segments
- **zsh plugins** — autosuggestions + syntax highlighting
- **dev aliases** — Claude Code (`cc`, `ccc`, `ccp`), git (`gs`, `gd`, `gl`), Docker (`dc`, `dcu`), Kubernetes (`k`, `kgp`, `kl`), mise (`mi`, `mu`, `ml`)

Use `--skip-shell` to skip, or run standalone: `bash shell/setup.sh`.

## What's Not Here

Sub-agents, hooks, MCP server configs, agent teams, and external plugin cloning were removed in v3.0.0. Plugins come from the Claude Code marketplace now:

```bash
claude plugin install impeccable@impeccable
claude plugin install expo@claude-plugins-official
```

Marketplace plugins auto-update. Git clones freeze at the commit you cloned.

Clerk skills are deliberately excluded — they live in `~/.agents/skills/` and are symlinked into `~/.claude/skills/` by Clerk's own tooling.

## The Delavalom Pipeline

```
THINK -> RESEARCH -> PLAN -> BUILD -> REVIEW -> SECURE -> SHIP -> REFLECT
```

1. **Think** — define the problem; `architect` for anything non-trivial
2. **Research** — `how` and `why` on existing code, WebSearch for outside context
3. **Plan** — architecture decisions and scope, sketched before implementation
4. **Build** — implement against the sketch, in a `run-loop`, guided by the `principle-*` skills
5. **Review** — `adversarial-review` before the commit, `/code-review` and `blast-radius` after
6. **Secure** — `/security-review` before deployment
7. **Ship** — `use-railway` or `/vercel:deploy` depending on the target
8. **Reflect** — `principle-prove-it-works`, save learnings, update `.claude/CLAUDE.md`

## Language Preferences

| Domain | Language | Rationale |
|--------|----------|-----------|
| Infrastructure / CLI | Go | Fast, compiled, K8s-native |
| Data / ML / Scripts | Python | Ecosystem, libraries, notebooks |
| Web frontend | TypeScript + React | Component model, type safety |
| Web backend / APIs | TypeScript or Python | Depends on project requirements |
| Performance-critical | Rust | Memory safety, speed |
| Data pipelines | SQL + Python | Unified transforms |
| Quick automation | Bash | Glue scripts, CI/CD |

## Attribution

Most skills here are mine. These are vendored from [cursor/plugins](https://github.com/cursor/plugins) (`pstack`), MIT, copyright Lauren Tan, and are kept close to upstream so they stay easy to re-sync:

`arena`, `interrogate`, `maintain-verification-skill`, `tdd`, and the `principle-*` skills other than `principle-no-cope`, `principle-model-the-domain`, `principle-boundary-discipline`, `principle-make-operations-idempotent`, and `principle-prove-it-works`.

They were copied because skills already in this repo referenced them by name and the references were dangling. A few still mention Cursor-specific paths (`~/.cursor/rules/pstack-models.mdc`, `.cursor/skills/`); they degrade to their documented defaults when those files are absent.

`run-loop`, `adversarial-review`, `harden-the-loop`, and `principle-no-cope` are original to this repo.

## License

MIT
