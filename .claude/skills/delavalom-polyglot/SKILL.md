---
name: delavalom-polyglot
description: Multi-language codebase guidance — when to use Go, Python, TypeScript, Rust, and cross-language patterns
version: 1.0.0
author: Luis Arvelo (Delavalom)
triggers:
  - polyglot
  - language choice
  - cross-language
  - which language
  - refactor across languages
---

# Polyglot Codebase Skill

## Purpose
Guide language selection and cross-language patterns across the Delavalom stack. Prevent language sprawl while leveraging each language's strengths.

## Language Decision Matrix

### Go — Infrastructure, CLI, Backend Services
**Use when:** Building CLI tools, K8s operators, high-concurrency services, network proxies, data pipeline orchestration (bruin-style).
**Patterns:** Error handling via explicit returns (no exceptions), goroutines for concurrency, interfaces for abstraction, minimal dependencies.
**Anti-patterns:** Don't use Go for ML/data science, rapid prototyping, or frontend.
**Style:** gofmt enforced, golangci-lint, table-driven tests, no global state.

### Python — Data, ML, Scripts, Research
**Use when:** Data pipelines, ML model training/serving, Jupyter notebooks, quick scripts, API prototypes (FastAPI), scientific computing.
**Patterns:** Type hints everywhere, pydantic for validation, async for I/O-bound, pytest for testing, ruff for linting.
**Anti-patterns:** Don't use Python for performance-critical paths, large frontend apps, or compiled CLI tools.
**Style:** PEP 8 via ruff, type hints (strict), docstrings on public functions, virtual environments (uv preferred).

### TypeScript — Web, APIs, Full-Stack
**Use when:** React frontends, Next.js apps, Node/Bun APIs, Claude Code skills/plugins, real-time features.
**Patterns:** Strict mode, Zod for runtime validation, React Query for data fetching, Tailwind for styling.
**Anti-patterns:** Don't use TS for system programming, heavy computation, or data pipelines.
**Style:** ESLint + Prettier, strict tsconfig, no `any` types, prefer `const` assertions.
**React rules:** Always enforce no-use-effect patterns. Use impeccable for design quality.

### Rust — Performance-Critical, Systems
**Use when:** Vector operations (RuVector), cryptography, WASM modules, anything requiring memory safety + speed.
**Patterns:** Ownership model, trait-based abstractions, error handling via Result<T,E>, cargo workspaces.
**Anti-patterns:** Don't use Rust for rapid prototyping, simple scripts, or when team expertise is low.
**Style:** cargo fmt, clippy (deny warnings), documentation tests.

### SQL — Data Transforms
**Use when:** Data pipeline transformations (via bruin), analytics queries, database migrations.
**Patterns:** CTEs for readability, window functions for analytics, materialized views for performance.
**Style:** Uppercase keywords, lowercase identifiers, one clause per line.

### Bash — Automation Glue
**Use when:** CI/CD scripts, deployment automation, quick file operations, environment setup.
**Patterns:** set -euo pipefail, shellcheck clean, functions for reuse, trap for cleanup.
**Anti-patterns:** Don't use Bash for anything over 100 lines — switch to Python or Go.

## Cross-Language Communication Patterns

### API Boundaries
- Define interfaces via OpenAPI/protobuf at service boundaries
- Use JSON for REST, protobuf for gRPC (high-throughput internal services)
- Version APIs explicitly (path-based: /v1/, /v2/)

### Shared Types
- Generate types from a single source of truth (OpenAPI spec or protobuf)
- Never manually maintain the same type definition in two languages

### Monorepo vs Polyrepo
- **Monorepo** when services share types/contracts frequently
- **Polyrepo** when services are truly independent
- Luis's stack: treat as a meta-repo with per-project independence but shared CLAUDE.md context

## Migration Patterns
When migrating between languages:
1. Define the interface boundary first
2. Write the new implementation behind a feature flag
3. Run both old and new in parallel with comparison logging
4. Switch traffic gradually (canary pattern)
5. Remove old implementation only after 2 weeks of stable operation
