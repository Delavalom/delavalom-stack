# Delavalom Stack Plugin

Shared Claude Code development workspace for multi-domain engineering.

## What's Included

- **7 Sub-Agents**: reviewer, debugger, researcher, k8s-ops, data-eng, frontend, content
- **4 Domain Skills**: k8s operations, content distribution, polyglot codebase, cross-project knowledge
- **3 Hooks**: --no-verify blocking, pre-push review reminder, doc modification warning
- **7 MCP Servers**: github, filesystem, memory, sequential-thinking, playwright, context7, exa-web-search
- **Agent Teams**: experimental multi-agent coordination enabled

## Installation

### Full Install (recommended)
```bash
git clone https://github.com/delavalom/delavalom-stack.git
cd delavalom-stack
bash install.sh --full
```

This auto-installs 7 external plugins (superpowers, gstack, impeccable, oh-my-claudecode, marketingskills, no-use-effect, everything-claude-code).

### Add to Another Project
```bash
bash install.sh --project /path/to/your-project
```

### Agents Only
```bash
bash install.sh --agents
```

### Dry Run (preview)
```bash
bash install.sh --full --dry-run
```

## The Delavalom Pipeline

```
THINK -> RESEARCH -> PLAN -> BUILD -> REVIEW -> SECURE -> SHIP -> REFLECT
```

## Uninstall

```bash
bash install.sh --uninstall
```
