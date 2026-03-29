# Delavalom Stack — Master Context

## Who Is Luis Arvelo

Luis is a senior full-stack engineer, data engineer, and founder working across multiple domains simultaneously. He operates at the intersection of engineering, data infrastructure, ML/AI, marketing/GTM, and finance. His projects span Kubernetes-orchestrated services, data pipelines, web applications, chat platforms, deployment tools, custom frameworks, and content distribution systems.

Luis prefers thorough, structured work with clear reasoning behind every decision. He values DRY principles — write something once, make it reusable, and improve it iteratively. He already knows Claude Code well and wants to push it to maximum productivity.

## Work Domains

### Engineering & Infrastructure
- Kubernetes orchestration, multi-cell architectures, service mesh
- Multi-language codebases: Go (infrastructure), Python (data/ML), TypeScript (web), Rust (performance)
- CI/CD pipelines, deployment automation, container management
- Multiple applications: chat platforms, blogger deployment tools, custom frameworks

### Data Engineering & ML
- Data pipelines connecting multiple sources (GitHub, Google, various content systems)
- ML model serving, data quality, feature engineering
- Finance file processing and analytics

### Marketing & Go-to-Market
- Content creation and distribution across platforms
- SEO optimization and search presence
- Conversion optimization, audience building
- Personal brand development

### Finance
- Processing incoming finance documents
- Reporting, analysis, budget tracking

## Style Rules

1. **Thorough & structured** — explain reasoning, show your work, make decisions transparent
2. **DRY everything** — if something exists, reference it; don't recreate
3. **Short and defined** — skills, configs, and docs should be concise and improvable
4. **Iterative improvement** — start with a working version, then refine
5. **Cross-project awareness** — always consider how a decision affects other projects in the stack

## Installation

This stack is installed via `install.sh`. Run `bash install.sh --full` for the complete setup including all external plugins. See README.md for all installation modes.

## Active Skill Stack (Tiered Loading)

### Tier 1 — Always Active
- **oh-my-claudecode** — Agent orchestration, smart model routing, token optimization
- **superpowers** — TDD (RED-GREEN-REFACTOR), systematic debugging, code review patterns
- **impeccable** — Frontend design quality enforcement, anti-generic-AI patterns
- **no-use-effect** — React anti-patterns (always load for React projects, zero cost)

### Tier 2 — Per Domain
- **gstack** — Sprint workflows: /review, /qa, /ship, /cso, /canary, /retro
- **marketingskills** — GTM, SEO, content, CRO, email
- **everything-claude-code** — Cherry-pick specific skills (don't load entire pack)

### Tier 3 — On Demand
- **claude-mem** — Long-running project memory across sessions
- **last30days-skill** — Real-time research (Reddit, X, YouTube, HN, Polymarket)
- **claude-scientific-skills** — Scientific research projects only

## Workflow: The Delavalom Pipeline

```
THINK → RESEARCH → PLAN → BUILD → REVIEW → SECURE → SHIP → REFLECT
```

1. **Think** — OMC + superpowers brainstorming, define problem clearly
2. **Research** — last30days for trends, WebSearch for context, competitive analysis
3. **Plan** — gstack /plan-ceo-review, architecture decisions, scope definition
4. **Build** — OMC agent delegation + superpowers TDD, parallel subagents for independent tasks
5. **Review** — gstack /review (staff-engineer level) + impeccable /audit (frontend)
6. **Secure** — gstack /cso (OWASP/STRIDE quick check)
7. **Ship** — gstack /ship (release engineering) + /canary (post-deploy monitoring)
8. **Reflect** — gstack /retro, save learnings to memory, update this context

## Custom Sub-Agents (7)

### User-Level (available across all projects via ~/.claude/agents/)
- **delavalom-reviewer** — Staff-level code review (Sonnet, read-only tools)
- **delavalom-debugger** — Root-cause analysis specialist (inherits model, full tools)
- **delavalom-researcher** — Fast codebase exploration (Haiku, read-only, background)

### Project-Level (available in this stack via .claude/agents/)
- **delavalom-k8s-ops** — Kubernetes operations (Sonnet, uses delavalom-k8s skill)
- **delavalom-data-eng** — Data pipeline specialist (inherits model, uses bruin patterns)
- **delavalom-frontend** — Frontend with design enforcement (Sonnet, uses impeccable + no-use-effect)
- **delavalom-content** — Content creation + distribution (Sonnet, uses delavalom-distribute skill)

## Agent Teams

Agent teams enable multi-instance coordination for tasks requiring parallel work with inter-agent communication. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (already set in settings.json).

### When to Use Teams vs Sub-Agents
- **Single focused task** → Sub-agent
- **Multiple independent tasks** → Parallel sub-agents
- **Tasks requiring discussion/coordination** → Agent team
- **Sequential dependent work** → Main conversation

### Team Patterns
- **Parallel Code Review** — 3 teammates review same PR from security, performance, test coverage
- **Competing Hypothesis Debug** — 5 teammates investigate different root causes simultaneously
- **Cross-Layer Feature Build** — Frontend, backend, and test teammates each own their domain
- **Research Sprint** — Teammates research different segments/competitors in parallel

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

## MCP Servers (Curated)

### Always On
- github, filesystem, memory, sequential-thinking

### Development
- playwright, context7

### Research & Content
- exa-web-search

## Key Principles

- **Context is currency** — minimize token waste, maximize signal-to-noise
- **Layer, don't replace** — orchestration tools complement each other at different scales
- **Progressive disclosure** — load SKILL.md first, dive into details only when needed
- **Memory is for the non-obvious** — don't save what you can derive from code or git
- **Security is not optional** — run /cso before any deployment
- **Cross-project learning** — patterns discovered in one project should propagate to others
