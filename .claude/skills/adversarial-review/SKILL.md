---
name: adversarial-review
description: "Review a diff with reviewers that never saw the reasoning behind it, on model families that did not write it. Use for /adversarial-review, 'review this properly', 'have another model check this', or before committing anything broad, subtle, or security-adjacent."
disable-model-invocation: true
---

# Adversarial review

One implementer, several reviewers, strict separation. The implementer never reviews. The reviewers never write code, never see the plan, and run on different model families wherever the machine allows it.

The separation is the whole mechanism. An agent reviewing its own diff has already been convinced once, and re-reading its reasoning convinces it again — that is confirmation bias with the volume turned up, not verification. A reviewer holding the same weights shares the same blind spots and misses the same bug for the same reason. Fresh eyes have to actually be fresh: different context, different model.

## Start

Open a todolist with one entry per phase.

1. Frame
2. Isolate
3. Fan out
4. Triage
5. Act

## Phase A: Frame

State what is under review and get it into one file.

```bash
git diff > /tmp/ar-<slug>/change.diff              # working tree
git diff main...HEAD > /tmp/ar-<slug>/change.diff   # whole branch
gh pr diff <n> > /tmp/ar-<slug>/change.diff         # a PR
```

Note anything genuinely load-bearing that the diff alone cannot show — a wire format the diff serializes, a migration that already ran — and pass it as the optional `focus` argument. Keep it factual. `focus` is for facts the reviewer cannot read off the repo, never for what you were trying to do or why you think it is correct.

Review one coherent change at a time. Ten unrelated commits in one diff produce shallow findings on all ten.

## Phase B: Isolate the reviewers

Reviewers get the diff and read-only access to the repo. They do not get your plan, your rationale, your commit message body, your transcript, or this conversation.

`scripts/review.sh` enforces this by construction: it builds the reviewer prompt from `references/reviewer-prompt.md` plus the diff, and nothing else. Do not "help" a reviewer by pasting in context. The moment a reviewer knows why you did it, it starts grading your reasoning instead of the code, and you have paid for a second opinion that agrees with the first.

## Phase C: Fan out

```bash
scripts/fanout.sh <diff-file> <out-dir> [focus]
```

It probes which reviewer CLIs can actually complete a call, runs the authenticated ones in parallel, and merges the results into `<out-dir>/merged.json`. It merges only the verdicts produced by the current run and exits 4 if every reviewer failed, so a stale file from an earlier review can never be presented as this one's result.

The diff is fenced as data in the reviewer prompt, with an explicit instruction not to obey anything inside it. A diff is untrusted input: text in a comment telling the reviewer to return an empty result is a real way to buy a clean review.

The probe makes a real call rather than checking for credential files, because credential files sit on disk looking valid while the CLI fails to authenticate. Verified on this machine: `~/.gemini/settings.json` declares an auth type and `oauth_creds.json` exists, and `gemini` still refuses to run. Treat any runner the probe does not mark `ok` as absent.

Runners, in rough order of usefulness here:

| Runner | Family | Notes |
|---|---|---|
| `codex` | OpenAI | Read-only sandbox, and `--output-schema` makes the JSON shape a hard constraint. The most reliable of the three. |
| `gemini` | Google | Read-only via `--approval-mode plan`. No schema enforcement, so output is salvaged by the parser. Needs `GEMINI_API_KEY` or a working OAuth login. |
| `cursor` | mixed | Headless via `-p`. Prompts for sign-in when unauthenticated, so never invoke it outside the probe. |

**When no external runner is authenticated**, fall back to in-harness subagents: spawn 2+ `Explore` agents with `model` set to a family other than yours, passing the same `references/reviewer-prompt.md` and the diff path. Context isolation still holds — a fresh subagent has never seen your reasoning. Say plainly in the report that heterogeneity was reduced to one vendor. That is a weaker review, and the reader has to know it (the **principle-no-cope** skill).

Two reviewers is the floor. One reviewer is a second opinion, not an adversarial review.

For generating candidate *fixes* across models rather than critiques, use the **arena** skill. Arena picks a winner and grafts; this skill collects defects and does not touch code.

## Phase D: Triage

`merged.json` groups findings that landed on the same file within three lines. Work the groups in this order.

1. **Corroborated.** Two families with no shared context landed on the same place. Confirm first that they are describing the *same* defect — the merge groups by proximity, and findings three lines apart are sometimes two different bugs. Once confirmed, genuine agreement between isolated reviewers is the strongest signal in the run. Treat it as real until you have run something that says otherwise.
2. **Blocker or major, single source.** Verify before acting. A finding is a claim, and reviewers hallucinate callers, invent APIs, and misread control flow with total confidence.
3. **`no_cope_violations`.** Each one is a place where the diff argues instead of fixing. Fix the code or delete the argument.
4. **Minor and speculative.** Read them, act only on what is obviously right.

Verify by running code, not by re-reading the diff and deciding whether you agree. Reach for the ladder in the **blast-radius** skill: pointing at the line beats asserting, running it beats pointing. When a finding claims a crash, write the four-line script that calls it with those inputs and watch what happens.

Reject a finding when you have evidence it is wrong. Record what you ran. "I don't think that's right" is not a rejection.

## Phase E: Act

Fix what survived triage, then re-run the **run-loop** skill's gate — every fix is a new change and inherits none of the old change's verification.

Re-review only when the fixes were substantial enough to be new work. A second round on a one-line fix burns money for noise.

## What to hand back

- **Roster.** Which runners actually ran, and which were skipped and why. Name them.
- **Corroborated findings**, with what you ran to confirm or kill each one.
- **Fixed**, with the commit or `file:line`.
- **Rejected**, each with the evidence that killed it.
- **Copes**, and what happened to each.
- **Unverified**, if you ran out of road. Mark it unverified. Do not round up.

An empty result is a real outcome. Reviewers finding nothing on a small clean diff means the diff is clean, and inventing a finding to justify the run costs more than the run did.
