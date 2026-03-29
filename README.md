# Delavalom Stack — Shared Claude Code Development Workspace

A portable, one-command-installable Claude Code configuration that includes 7 custom sub-agents, 4 domain skills, governance hooks, MCP server configs, and auto-installs 7 curated external plugins. Designed for a senior full-stack engineer working across engineering, data, marketing, and finance.

## Quick Start

```bash
git clone https://github.com/delavalom/delavalom-stack.git
cd delavalom-stack
bash install.sh --full
```

## What's Included

### 7 Sub-Agents (3 user-level, 4 project-level)

| Agent | Level | Role |
|-------|-------|------|
| reviewer | user | Staff-engineer-level code review |
| debugger | user | Systematic debugging with root cause analysis |
| researcher | user | Real-time research across sources |
| k8s-ops | project | Kubernetes operations and troubleshooting |
| data-eng | project | Data pipeline development and quality |
| frontend | project | Frontend development with design enforcement |
| content | project | Content creation and distribution |

### 4 Custom Skills

- **k8s operations** -- Cluster management, deployment, service mesh workflows
- **content distribution** -- Multi-platform publishing and SEO optimization
- **polyglot codebase** -- Cross-language patterns for Go, Python, TypeScript, Rust
- **cross-project knowledge** -- Pattern propagation across the 24+ project workspace

### 3 Hooks

- **--no-verify blocking** -- Prevents bypassing git hooks
- **pre-push review reminder** -- Prompts for review before pushing
- **doc modification warning** -- Alerts when documentation files are changed

### 7 MCP Servers

github, filesystem, memory, sequential-thinking, playwright, context7, exa-web-search

### Agent Teams

Experimental multi-agent coordination enabled for parallel task execution and consensus-based decision making.

## External Plugins Auto-Installed

The `--full` flag clones and configures these plugins:

| Plugin | Skills | Purpose |
|--------|--------|---------|
| superpowers | 14 | TDD, debugging, code review methodology |
| gstack | 28 | Sprint workflows: /review, /qa, /ship, /cso |
| impeccable | 22 | Frontend design quality, anti-AI-generic patterns |
| oh-my-claudecode | 32 | Agent orchestration, smart model routing |
| marketingskills | 33 | GTM, SEO, CRO, email, content strategy |
| no-use-effect | 1 | React anti-patterns (zero token cost) |
| everything-claude-code | 125 | Full SDLC skills across 12 languages |

## Installation Modes

```bash
bash install.sh --full          # Everything + plugins (default)
bash install.sh --project /path # Copy stack into another project
bash install.sh --user          # User-level agents only
bash install.sh --minimal       # Agents + CLAUDE.md
bash install.sh --agents        # 7 agents only
bash install.sh --skip-plugins  # Full but skip plugin cloning
bash install.sh --dry-run       # Preview without changes
bash install.sh --uninstall     # Clean removal
```

## The Delavalom Pipeline

```
THINK -> RESEARCH -> PLAN -> BUILD -> REVIEW -> SECURE -> SHIP -> REFLECT
```

1. **Think** -- Define the problem clearly using brainstorming and structured reasoning.
2. **Research** -- Gather trends, context, and competitive analysis from live sources.
3. **Plan** -- Architecture decisions, scope definition, CEO-level review of approach.
4. **Build** -- TDD-driven development with parallel agent delegation for independent tasks.
5. **Review** -- Staff-engineer-level code review plus frontend design audit.
6. **Secure** -- OWASP/STRIDE quick check and deep security scanning before deployment.
7. **Ship** -- Release engineering with post-deploy canary monitoring.
8. **Reflect** -- Retrospective, save learnings to memory, update context for next cycle.

## Language Preferences

| Domain | Language | Rationale |
|--------|----------|-----------|
| Infrastructure / CLI | Go | Fast, compiled, K8s-native |
| Data / ML / Scripts | Python | Ecosystem, libraries, notebooks |
| Web frontend | TypeScript + React | Component model, type safety |
| Web backend / APIs | TypeScript or Python | Depends on project requirements |
| Performance-critical | Rust | Memory safety, speed |
| Data pipelines | SQL + Python | Unified transforms via bruin |
| Quick automation | Bash | Glue scripts, CI/CD |

## License

MIT
