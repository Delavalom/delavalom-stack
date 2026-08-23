# Delavalom Stack Plugin

A portable Claude Code skill set: 16 vendored skills for architecture, code archaeology, engineering principles, verification, writing, and infrastructure.

## What's Included

- **Design & architecture**: `architect`, `how`, `why`, `blast-radius`
- **Engineering principles**: `principle-model-the-domain`, `principle-boundary-discipline`, `principle-make-operations-idempotent`, `principle-prove-it-works`
- **Verification & process**: `create-verification-skill`, `show-me-your-work`
- **Writing**: `technical-writing`, `unslop`, `bro`
- **Frontend & infrastructure**: `no-use-effect`, `clone-webapp`, `use-railway`

Plus a mise/starship/zsh shell setup.

## Installation

### Full install (recommended)
```bash
git clone https://github.com/delavalom/delavalom-stack.git
cd delavalom-stack
bash install.sh --full
```

### Skills only
```bash
bash install.sh --skills
```

### Add to another project
```bash
bash install.sh --project /path/to/your-project
```

### Dry run (preview)
```bash
bash install.sh --full --dry-run
```

## Uninstall

```bash
bash install.sh --uninstall
```

See the [repo README](../README.md) for the full skill table and details.
