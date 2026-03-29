---
name: delavalom-cross-project
description: Cross-project knowledge sync — registry of all projects, shared patterns, lessons learned, and cross-references
version: 2.0.0
author: Luis Arvelo (Delavalom)
triggers:
  - cross-project
  - all projects
  - project registry
  - shared patterns
  - which project
---

# Cross-Project Knowledge Sync

## Purpose
Maintain awareness of all projects and tools in the Delavalom ecosystem so patterns, decisions, and lessons propagate across projects instead of staying siloed.

## Installed Plugins Registry

These are auto-installed by `install.sh --full` to `~/.claude/skills/`:

| Plugin | Skills | Domain | Key Commands |
|--------|--------|--------|-------------|
| oh-my-claudecode | 32 | Agent orchestration | /omc-setup, /plan, /team |
| superpowers | 14 | Methodology | TDD, debugging, code review |
| gstack | 28 | Sprint workflow | /review, /qa, /ship, /cso, /retro |
| impeccable | 22 | Frontend design | /audit, /polish, /distill |
| marketingskills | 33 | GTM / Marketing | SEO, CRO, email, content |
| everything-claude-code | 125 | Full SDLC | Cherry-pick per language/task |
| no-use-effect | 1 | React quality | Zero-cost anti-patterns |

## Custom Skills (bundled in .claude/skills/)

| Skill | Purpose |
|-------|---------|
| delavalom-k8s | Kubernetes operations, pod debugging, Helm, deployments |
| delavalom-distribute | Content distribution pipeline across platforms |
| delavalom-polyglot | Multi-language decision framework (Go/Python/TS/Rust) |
| delavalom-cross-project | This skill — project awareness and patterns |

## Cross-Project Patterns

### Pattern: Multi-Expert Consensus
**Origin:** ai-hedge-fund (18 competing investor agents)
**Applies to:** Marketing strategy, architecture reviews, content strategy
**How:** Spawn multiple agents with different perspectives, aggregate via consensus

### Pattern: Progressive Disclosure
**Origin:** Agent-Skills-CE, claude-mem
**Applies to:** All skill design, context management
**How:** SKILL.md → MODULE.md → detailed data. Load only what's needed.

### Pattern: Staged Pipeline
**Origin:** oh-my-claudecode (plan → exec → verify → fix)
**Applies to:** Every non-trivial task
**How:** Never ship without the verify step. Automate the fix loop.

### Pattern: Anti-Pattern Enforcement
**Origin:** impeccable (design), no-use-effect (React)
**Applies to:** Every domain — define what NOT to do alongside what to do
**How:** Explicit anti-pattern lists in every skill, with explanations of why

### Pattern: DRY Configuration
**Applies to:** K8s manifests, CI/CD configs, CLAUDE.md files
**How:** Single source of truth, generate variants, never copy-paste

## Lessons Learned

1. **Token budget matters** — Loading all skills kills performance. Tier your loading.
2. **Memory is for the non-obvious** — Don't save what git log or code reading can tell you.
3. **Security is not optional** — Run /cso before every deploy.
4. **Cross-language types** — Always generate from a single spec, never maintain duplicates.
5. **Content != distribution** — Creating content is half the work; distributing it is the other half.

## When to Consult This Skill
- Starting a new project (check if a pattern already exists)
- Making an architecture decision (check cross-project implications)
- Debugging a recurring issue (check if another project solved it)
- Building a new skill (check for reusable patterns)
- Reviewing code (check for consistency with other projects)
