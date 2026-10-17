# Project conventions

These exist so the clone stays honest and the backend swap stays mechanical.

## Layout

```
docs/SPEC.md            the contract — describes the ORIGINAL
docs/PLAN.md            phases, done and remaining
src/app/(app)/          routes — thin; state lives in the URL
src/components/
  ui/                   primitives + media placeholders
  shell/                nav, panels, shortcuts
  <feature>/            one folder per major surface
src/lib/
  types.ts              domain model — mirrored by convex/schema.ts
  utils.ts              shared formatters (numbers, dates)
  use-url-state.ts      read/write query params
  data/
    seed.ts             deterministic dummy dataset
    store.ts            local mutations (zustand + persist)
    queries.ts          read hooks   ← the seam
    mutations.ts        write hooks  ← the seam
convex/schema.ts        complete; functions are stubs
convex/README.md        how to bring it online
```

## The seam — the whole point

**Components never import `seed.ts`.** They call hooks, and every hook is named
after the Convex function it becomes and says so in its doc comment:

```ts
/** convex: api.creatives.list({ accountId, search, filters, limit }) */
export function useCreatives(query: CreativeQuery = {}): Creative[] { … }
```

```ts
/** convex: api.boards.create({ name, description }) */
export const useCreateBoard = () => useDataStore((s) => s.createBoard);
```

Bringing the backend online then means: implement `convex/*.ts`, and change each
hook body from a store read to `useQuery(api.…)`. One file at a time — a
half-migrated app still runs, because everything goes through the seam.

`convex/schema.ts` mirrors `lib/types.ts` **field for field**. Keep them in sync
in the same commit, always.

## Derive analytics, don't store them

Compute mixes, breakdowns, funnels and timeseries from the entity list at read
time inside `queries.ts`. A filtered list and its summary widgets can then never
disagree, and the same code works against Convex unchanged.

The exception is window-over-window deltas — there's no previous window in a
static dataset. Generate them from a seed, and isolate that in **one** named
function so there's a single place to replace later.

## Deterministic data

Server and client must render identically.

- Seed everything from a hash-based PRNG (`rng(seed)`), never `Math.random()`.
- Pin "now" to a constant (`export const NOW = Date.UTC(...)`) — the capture
  date. Every relative label ("2 days ago", "Last 90 days") reads off it.
- No `Date.now()` or `new Date()` during render.

Scale volumes to what the original shows. A chart built on 26 rows looks like a
sawtooth; the original had hundreds. Bias timestamps toward recent so density
matches.

## URL is the state container

Filters, active tab, open modal, open drawer — all query params, in the
original's exact encoding. Reproduce even awkward encodings verbatim; a URL
copied out of the real app should open correctly in the clone.

## Theming

Put light, dark **and auto** entirely in CSS:

- light tokens on `:root`
- dark values parked as `--dk-*` on `:root`, promoted by
  `:root[data-theme="dark"]` **and** by
  `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }`
- an inline `<script>` in the root layout reads the persisted preference and
  sets `data-theme` before first paint

Auto then needs no listener, the setting needs no effect, and a reload never
flashes the wrong theme.

## No `useEffect`

Enforced by the user's global `no-use-effect` skill; it applies here.

- Browser subscriptions (document listeners, intervals) → own them through
  `useSyncExternalStore`'s **subscribe** contract. Return a constant snapshot
  when you're subscribing for the side effect only, and drive rendering with
  ordinary `useState`.
- DOM writes (setting `data-theme`) → in the event handler or store action.
- Don't write to a ref during render — modern React lint rejects it. Pass a
  `useCallback`-stable handler into the subscribe dependency list instead.

## Media placeholders

Real assets sit behind a CDN you shouldn't hotlink. Render deterministic
gradients seeded off an asset id, with the ad/headline text drawn over them, so
every tile is distinct and stable. Keep the component's shape identical to a
real `<Image>` so swapping in URLs later is a one-file change.

## Verification bar

`npx tsc --noEmit`, `pnpm lint` and `pnpm build` all clean — **and** every route
opened in the browser and compared against the recon screenshots. Types passing
means nothing about whether a chip renders a stray colon.

## AGENTS.md

Append the hard rules to the cloned repo so future sessions inherit them: SPEC
is the contract, no `useEffect`, never import seed data in components, keep
types and schema in sync, data stays deterministic, URL holds view state.
