---
name: clone-webapp
description: Clone the frontend of a live web app from its URL alone. Walks every page in Chrome, writes a page-by-page spec, then scaffolds and builds a working Next.js + Tailwind copy running on dummy data behind a Convex-ready seam. Use when asked to clone, copy, replicate or rebuild an app, site or dashboard given its domain — e.g. "clone app.example.com", "/clone-webapp example.com", "make a frontend copy of this tool".
---

# Clone a web app's frontend

**Argument:** the URL or domain. Nothing else is required.
`/clone-webapp app.spyglass.so` → `~/delavalom-labs/spyglass-clone`.

Optional second argument overrides the target directory.

The deliverable is a **running app**, not a report: every route, component,
interaction, empty state and loading state, on a local dummy dataset, with the
backend seam already cut so Convex drops in later.

---

## 0. Gate: can you actually see the app?

Open the URL in Chrome (`claude-in-chrome` skill first, then
`tabs_context_mcp` → `tabs_create_mcp` → `navigate`).

- **Redirected to a marketing site / login wall** → you cannot proceed.
  You may not create accounts or enter credentials. Stop and ask the user to
  sign in to that Chrome profile themselves, then resume. Say exactly that.
- **You land in the app** → continue. The user's existing session is what makes
  this work.

Also decide what you're looking at. If it's a marketing site, a single page, or
something the Next.js + dummy-data default doesn't fit, say so in one sentence
and ask before building. Otherwise assume the defaults in §3 and don't ask.

## 1. Recon — walk every page

Follow `references/RECON.md`. It is a checklist; work it, don't improvise.

The output of this phase is notes, not code. Do not start scaffolding until the
route map is complete — a spec written from half the app produces a component
tree you throw away.

Budget: this is the expensive phase and it is the one that determines quality.
Spend the calls. Batch with `browser_batch`.

## 2. Write the contract

Two files, before any code:

- **`docs/SPEC.md`** — describes the **original**, not your repo. Page by page:
  layout, copy, every interaction, empty and loading states, URL shape. Plus
  design tokens, the route map, the domain model, and an explicit "what's in
  scope / what's dummy" section. Number the sections; components will cite them.
- **`docs/PLAN.md`** — phases, what each delivers, and what you're knowingly
  leaving out.

State the route inventory in chat so the user can see the surface area. Then
keep going — don't block on approval unless §0 flagged something.

## 3. Scaffold

Defaults, unless recon showed the original differs and matching it is cheap:

```
pnpm dlx create-next-app@latest <name> --ts --tailwind --eslint --app \
  --src-dir --import-alias "@/*" --use-pnpm --no-turbopack --skip-install --yes
pnpm add clsx tailwind-merge lucide-react date-fns zustand convex geist
```

Match the original's stack where you detected it (§RECON step 5) — same
framework major, same font, same icon set. A clone that uses the same
primitives is dramatically easier to make pixel-accurate.

Then follow `references/CONVENTIONS.md` for the layout of `src/`, the data
seam, and the rules that make the Convex swap mechanical. Those conventions are
not optional; they are the reason "backend later" is a plan and not a wish.

## 4. Build

Order that works, because each layer unblocks the next:

1. `globals.css` design tokens (light + dark + auto), `lib/types.ts`, shared
   formatters, and any URL-state / filter-language module the app needs.
2. `lib/data/{seed,store,queries,mutations}.ts` + `convex/schema.ts`.
3. UI primitives and media placeholders.
4. App shell — nav, panels, global shortcuts.
5. The highest-traffic surface (usually a list/grid + its detail view).
6. Everything else, then the admin/settings/help tail.

Typecheck as you go. Don't write six files and then find out.

## 5. Verify — this is not optional

1. `npx tsc --noEmit` — clean.
2. `pnpm lint` — clean. Fix real findings properly; don't blanket-disable.
3. `pnpm build` — clean, and confirm the route list matches `docs/SPEC.md` §3.
4. **Open every route in Chrome and look at it.** Compare against your recon
   screenshots. This is where the real bugs surface — number formatting,
   stray punctuation in labels, z-index, overlapping chrome, chart axes.
   Fix what you find, then re-verify.
5. Exercise one write path end to end (create something, see it persist).

## 6. Land it

- `README.md`: what it is, how to run, the route list, the architecture map,
  and what's dummy.
- Append the project's hard rules to `AGENTS.md` (or `CLAUDE.md`).
- Commit on a branch with a message that says what was cloned and how.
- Write a `project` memory: repo path, that `docs/SPEC.md` is the contract, and
  any **non-obvious facts about the original** you can't re-derive without a
  login (its real stack, its URL encodings, distinctive interactions).

## Report

Say what you built, the deltas you knowingly left (cite PLAN.md phase), and
anything you couldn't reach. Never imply a route is faithful if you didn't open
it.

---

## Note on `/goal`

`/goal` is a **built-in CLI command**, not a skill — this skill can't invoke it,
and neither can Claude. It sets a completion condition that persists across
turns.

You don't need it here: this skill runs to completion in one turn. Use it only
if you want the run to survive interruption or auto-continue, and if you do,
just name the skill inside the condition — one command, not two:

```
/goal clone app.example.com with the clone-webapp skill until tsc, lint and
build are clean and every route in docs/SPEC.md renders
```

(Watch for a leading space before `/goal` — it stops the parser seeing it.)
