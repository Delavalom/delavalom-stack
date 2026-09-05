---
name: harden-the-loop
description: "Audit and fix a repo's feedback loop so an agent can verify its own work: one fast command, real error output, assertions that can actually fail. Use for /harden-the-loop, 'the tests are too slow to iterate on', 'agents keep claiming done without checking', or when run-loop finds no usable gate."
disable-model-invocation: true
---

# Harden the loop

Fix the environment, not the agent.

Instructions telling an agent to be careful, check its work, and think step by step decay across a long run. Stamina is not something it has. What does not decay is a command that exits non-zero and prints a stack trace, because reading the trace and fixing it is the path of least resistance rather than a discipline that has to be maintained.

So when an agent ships broken code in a repo, treat it as a defect in the repo. The question is never "how do I word the rule more firmly." It is "what could this agent have run that would have told it the truth, and why didn't it exist or why wasn't it cheap enough to run."

This skill audits that, then fixes what it finds. It changes build and test infrastructure, not product code.

## Start

Open a todolist with one entry per phase.

1. Measure
2. Diagnose
3. Fix
4. Prove
5. Document

## Phase A: Measure what exists

Do not read the CI config and write down what it claims. Run things and time them.

```bash
# What does the repo say it offers?
cat package.json | python3 -c "import json,sys;print(json.load(sys.stdin).get('scripts',{}))"
ls Makefile justfile mise.toml Taskfile.yml 2>/dev/null
ls .github/workflows/ 2>/dev/null

# What does it actually do? Time each one.
time <the test command>
time <the typecheck command>
time <the lint command>
```

Record for each candidate gate: the exact command, wall-clock time, whether failures print a usable location, and whether it needs network, a database, credentials, or a running server.

## Phase B: Diagnose

Score the loop on five properties. Each failure has a standard repair.

**1. Reachable.** One documented command runs the gate from a clean checkout. If the honest answer is "run these four things, but the second needs Docker up," the loop does not exist yet — nobody runs a four-step ritual on every edit.

**2. Fast.** Under 30 seconds for the narrow scoped gate, a few minutes for the full one. This is the property everything else depends on: a slow gate does not get run less carefully, it gets run *less*, and an unrun gate is worth exactly nothing. If the full suite is 20 minutes, the deliverable is a scoped entry point — per-file, per-package, changed-files-only — not a faster suite.

**3. Loud.** Failure prints the assertion, the actual value, and a `file:line`. These silently destroy a loop and are worth grepping for specifically:
   - `|| true`, `continue-on-error`, `--passWithNoTests`, `set +e` around the gate
   - stderr redirected to a file nobody reads
   - a custom reporter that prints a red X and a count, and swallows the diff
   - a wrapper that catches the exception and exits 0

**4. Honest.** Passing has to mean something. Two checks:
   - **Can it fail?** Break something real — invert a condition in a hot function, delete a return — and confirm red. A suite that stays green is decoration.
   - **Does it assert?** Grep the tests for assertion-free bodies and for assertions on a mock's own return value. A test that mocks a function and then asserts the mock returned what it was configured to return has tested the mocking library.

**5. Deterministic.** The same input gives the same result. Flakes are worse than absent tests, because a loop that fails randomly trains the agent — correctly — to ignore red. Find them by running the suite three times and diffing. Fix the cause (real time, real network, shared fixtures, test order dependence, unawaited async) rather than adding retries. Retries convert a visible flake into an invisible one.

## Phase C: Fix

Land these in dependency order; each is cheap and compounds.

1. **A named entry point.** `npm run gate`, `make gate`, `just gate` — one obvious verb, so nothing has to be rediscovered from CI config next time.
2. **A scoped variant.** `gate:file <path>` or `gate:changed` running against `git diff --name-only`. This is the one used in the tight loop, and its speed is the single highest-leverage number in the repo.
3. **Unswallowed output.** Remove the `|| true`, drop the muting reporter, let stderr reach the terminal.
4. **Real assertions** where Phase B found none. Do not backfill the whole suite; fix the checks covering code that changes often.
5. **Fixture isolation** for whatever was flaky. Fresh state per test, injected clock, no shared mutable module-level fixtures.
6. **A seeded fast path** if setup needs a database or a server: a committed script that brings the environment up reproducibly, and a scoped gate that runs against it.

Two things this skill does not do. It does not add a git hook — the loop is run because it is fast and useful, and a blocked commit teaches an agent to reach for `--no-verify`. It does not add lint rules dressed up as verification; formatting is not correctness.

## Phase D: Prove the hardened loop

Verify against the real thing, per the **principle-prove-it-works** skill. Paste each result.

1. Run the scoped gate on a clean tree. Green, and time it.
2. Break something on purpose. Run it. Red, with a `file:line` you could act on.
3. Restore. Run it. Green.
4. Run the full gate three times. Same result each time.

If step 2 is not red, nothing has been fixed yet, whatever the other steps say.

## Phase E: Document it where it will be found

Write the gate commands into the repo's agent-facing context file (`CLAUDE.md`, `AGENTS.md`) and its README, in one short block:

```
Gate:        <exact command>       # full, ~<n>s
Scoped gate: <exact command>       # while iterating, ~<n>s
```

Exact commands, real timings. This is the point where the value stops being a rule an agent has to remember and becomes a fact in its context — which is what "encode values in the environment" means in practice. The **principle-encode-lessons-in-structure** skill is the general form of the move.

Then run the **run-loop** skill against a real change and confirm the loop is genuinely usable. A gate that passes its own audit but is annoying in practice will get skipped, and you will not find that out from the audit.

## What to hand back

The five properties, each pass or fail with the evidence. What was changed, as a diff. The before and after timings for both gates. The Phase D mutation result, pasted. Anything still broken, named plainly and left broken rather than explained away (the **principle-no-cope** skill).
