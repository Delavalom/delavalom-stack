# Delavalom Stack — Master Context

## Who Is Luis Arvelo

Luis is a senior full-stack engineer, data engineer, and founder working across multiple domains simultaneously. He operates at the intersection of engineering, data infrastructure, ML/AI, marketing/GTM, and finance. His projects span Kubernetes-orchestrated services, data pipelines, web applications, chat platforms, deployment tools, custom frameworks, and content distribution systems.

Luis prefers thorough, structured work with clear reasoning behind every decision. He values DRY principles — write something once, make it reusable, and improve it iteratively. He already knows Claude Code well and wants to push it to maximum productivity.

## What This Repo Is

A portable skill set. The 36 skills in `.claude/skills/` are the vendored copy of Luis's global `~/.claude/skills/` (minus the Clerk skills, which come from `~/.agents/`), plus the verification core and the `pstack` skills the others reference. `install.sh` copies them back to `~/.claude/skills/`, into another project, or sets up the shell.

Everything else — sub-agents, hooks, MCP servers, agent teams, external plugin cloning — was removed in v3.0.0. Plugins are managed through the Claude Code marketplace (`claude plugin install`), not through this repo.

## Style Rules

1. **Thorough & structured** — explain reasoning, show your work, make decisions transparent
2. **DRY everything** — if something exists, reference it; don't recreate
3. **Short and defined** — skills, configs, and docs should be concise and improvable
4. **Iterative improvement** — start with a working version, then refine
5. **Cross-project awareness** — always consider how a decision affects other projects in the stack

## The Skills

### Design & architecture
- **architect** — sketch types, signatures, and module boundaries before writing code
- **how** — explain how a subsystem works; placement, ownership, and layering questions
- **why** — recover design rationale from source control, issues, docs, chat, and observability
- **blast-radius** — find what a change breaks outside the diff, then prove it with real code

### Engineering principles
- **principle-model-the-domain** — encode the domain in a structure, not scattered conditionals
- **principle-boundary-discipline** — concentrate validation at boundaries; keep logic pure
- **principle-make-operations-idempotent** — converge to the same state across crashes and retries
- **principle-prove-it-works** — verify against the real artifact before declaring done
- **principle-no-cope** — a workaround needing a paragraph of justification is a defect (model-invocable)
- **principle-fix-root-causes**, **principle-laziness-protocol**, **principle-subtract-before-you-add**, **principle-exhaust-the-design-space**, **principle-redesign-from-first-principles**, **principle-foundational-thinking**, **principle-outcome-oriented-execution**, **principle-encode-lessons-in-structure**, **principle-separate-before-serializing-shared-state**, **principle-minimize-reader-load**, **principle-guard-the-context-window** — vendored from pstack

### Verification & review
The merciless-verification core. Reviewers must not share context or a model family with the implementer.
- **run-loop** — failing check first, then loop on real terminal output until the gate is green (model-invocable)
- **adversarial-review** — 1 implementer, N reviewers; role-isolated, cross-vendor, `no_cope` enforced
- **harden-the-loop** — fix the repo's gate so it is fast, loud, honest, and deterministic
- **arena** — fan out N candidates at one task, pick a base, graft the losers' best parts in
- **interrogate** — adversarial pressure on a design before it becomes code
- **create-verification-skill** / **maintain-verification-skill** — generate and maintain a project-local skill that drives the real app
- **tdd** — make the bug executable before fixing it, when the test path is cheap
- **show-me-your-work** — keep a reviewable TSV decision trail for long or unattended runs

### Writing
- **technical-writing** — Diátaxis structure, Google style, STE instructions, Global English
- **unslop** — cut AI tells from any writing
- **bro** — restate the last message in plain language, no jargon

### Frontend & infrastructure
- **no-use-effect** — always active; never write `useEffect` directly in React or React Native
- **clone-webapp** — clone a live web app's frontend into a Next.js + Tailwind copy
- **use-railway** — Railway projects, services, deployments, environments, and troubleshooting
- **diagram-design** — branded architecture, flow, and data diagrams as standalone HTML/SVG/PNG

## Workflow: The Delavalom Pipeline

```
THINK → RESEARCH → PLAN → BUILD → REVIEW → SECURE → SHIP → REFLECT
```

1. **Think** — define the problem clearly; `architect` for anything non-trivial
2. **Research** — `how` and `why` on existing code, WebSearch for outside context
3. **Plan** — architecture decisions and scope, sketched before implementation
4. **Build** — implement inside `run-loop`: failing check first, green before commit
5. **Review** — `adversarial-review` before committing anything broad or subtle; `/code-review` and `blast-radius` after
6. **Secure** — `/security-review` before deployment
7. **Ship** — `use-railway` or `/vercel:deploy` depending on the target
8. **Reflect** — `principle-prove-it-works`, save learnings to memory, update this file

## Language Preferences

| Domain | Language | Rationale |
|--------|----------|-----------|
| Infrastructure / CLI | Go | Fast, compiled, K8s-native |
| Data / ML / Scripts | Python | Ecosystem, libraries, notebooks |
| Web frontend | TypeScript + React | Component model, type safety |
| Web backend / APIs | TypeScript (Node/Bun) or Python (FastAPI) | Depends on project |
| Performance-critical | Rust | Memory safety, speed |
| Data pipelines | SQL + Python | Unified transforms |
| Quick automation | Bash | Glue scripts, CI/CD |

## Key Principles

- **Context is currency** — minimize token waste, maximize signal-to-noise
- **Progressive disclosure** — load SKILL.md first, dive into references only when needed
- **Memory is for the non-obvious** — don't save what you can derive from code or git
- **Security is not optional** — run `/security-review` before any deployment
- **Verification is environmental, not motivational** — if an agent ships something broken, fix the gate, not the wording of the rule (`harden-the-loop`)
- **Never review your own diff alone** — the reviewer must not share your context, and should not share your model family (`adversarial-review`)
- **No copes** — a paragraph justifying a workaround is a bug report about that workaround
- **Cross-project learning** — patterns discovered in one project should propagate to others
