---
name: run-loop
description: "Use before committing, before claiming a change works, and while fixing any bug that has a runnable check. Makes the failure executable first, then loops build-run-read-edit against real terminal output until the gate is genuinely green. Triggers on 'commit this', 'is it working', 'run the tests', 'verify this change', or finishing an implementation."
---

# Run Loop

Get trapped in a fast local loop until the gate is green, before anything is committed and before anyone is told it works.

The failure mode this exists to kill: writing code, reading it back, finding it convincing, and declaring done. You are a poor judge of your own diff and an excellent judge of a stack trace. The loop replaces judgment with output.

## Start

Open a todolist with these phases before touching code.

1. Gate
2. Red
3. Loop
4. Cover
5. Commit

## Phase A: Find the gate

The gate is the fastest command that would fail if your change is wrong. Find it before writing code, because you will not go looking for it once you have a diff you like.

Look in this order and stop at the first real hit: the repo's own scripts (`package.json`, `Makefile`, `justfile`, `mise.toml`, `Cargo.toml`), CI config for what it actually runs, then the test directory layout.

Scope it down hard. `npm test` over 4,000 tests is not a gate, it is a coffee break — and a loop you won't run is a loop that doesn't exist. Find the narrowest true command: a single file, a `-k` filter, a package in the workspace. Budget under 30 seconds. Write the exact command into the todolist so every iteration runs the same thing.

Two things disqualify a gate, and both are common:

- **It cannot fail.** A suite of assertion-free smoke tests is green on a deleted function. Check by breaking your change on purpose in Phase C.
- **It swallows output.** A gate ending in `|| true`, or piping stderr to a log you never read, teaches you nothing. You need the trace in the terminal.

If no gate exists, or the one that exists is disqualified, stop and run the **harden-the-loop** skill. Building the gate is the work. Proceeding without one means everything after this point is guessing.

## Phase B: Red before green

Make the failure executable before you change production code. The **tdd** skill owns the method, including when a test is genuinely impractical and what to do instead — follow it rather than improvising.

The rule that survives every shortcut: run the check and watch it fail, for the reason you expect, before you fix anything. A test that has never failed has proven nothing. It might be asserting on a mock, targeting dead code, or passing on the broken build. You cannot tell by reading it.

## Phase C: The loop

Run. Read the actual output. Edit. Run again. No commentary between iterations, no reasoning about what the output probably says.

- **Read the real bytes.** Not the summary line, not the exit code alone. The first error, not the last — a cascade usually has one cause at the top.
- **Never edit the check to make it pass.** Changing an assertion to match broken behavior converts a caught bug into a shipped bug plus a test that now certifies it.
- **Change one thing per iteration.** Two simultaneous edits and a color change tells you nothing about which one did it.
- **Three failures on the same error means your model is wrong.** Stop editing. Add instrumentation, print the actual value, and read it. Guessing a fourth time costs more than looking.
- **Do not widen scope inside the loop.** A refactor you notice mid-loop goes on a list, not into the diff. It breaks the one-variable rule and hides which change fixed the failure.
- **Never silence the gate.** Skipping a flaky test, loosening a type, or adding `|| true` ends the loop without ending the problem. A flaky test is a real defect (the **principle-no-cope** skill).

Exit only on green output you have actually read in this session. Not remembered green, not "it was passing before that last edit."

## Phase D: Prove the gate covered the change

Green means the gate passed. It does not yet mean the gate was watching. Close that hole with one cheap check: break your change on purpose — invert a condition, return the wrong value, delete the new line — and confirm the gate goes red. Then restore it.

If the gate stays green while the code is broken, the gate never covered the change, and Phase C proved nothing. Go back to Phase B and write a check that fails.

This is one mutation, by hand, in ten seconds. Reach for real mutation-testing tooling only when the change is large enough to earn it.

## Phase E: Before the commit

The narrow gate proved the change. It did not prove the repo. Before committing, in order:

1. Run the full gate for the affected package or module. The narrow one had a filter on it; things break outside the filter.
2. Read your own diff, top to bottom, as a diff. Debug prints, commented-out code, a stray `.only` on a test, a hardcoded local path.
3. For a change that is broad, subtle, or touches something you don't fully own, run the **adversarial-review** skill. You are in the arena too: your diff gets reviewed by models that never saw your reasoning, before it lands, not after.
4. Reach for the **blast-radius** skill when the risk is outside the diff rather than inside it.

Commit only after this. If a step fails, you are back in Phase C — that is the loop working, not a setback.

## Reporting

Report evidence, not adjectives. Name the exact gate command, paste the failing output from Phase B and the passing output from Phase C, and state the Phase D mutation result. "Tests pass" without the command and its output is a claim, not a result.

If you exited the loop without green — ran out of road, hit a broken dependency, found the gate unfixable — say so in one line and stop. Do not commit and do not write a paragraph explaining why red is acceptable here (the **principle-no-cope** skill).
