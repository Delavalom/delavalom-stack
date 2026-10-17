# Recon checklist

The quality of the clone is decided here. Work the list.

Batch aggressively with `browser_batch` — navigate, wait, screenshot, click,
screenshot in one call. Waits of 5–9s are normal; these apps stream data and a
screenshot taken too early captures skeletons.

---

## 1. Map the routes

Start from the landing route and `read_page` (filter `all`). The accessibility
tree gives you every `href` on the page at once — far faster than clicking
around. Follow the nav, then follow links found inside pages (detail routes,
deep links from notification/alert rows).

Record for each route:
- the path pattern (`/research/account/[accountId]`)
- every query param it uses and what each controls
- which params survive navigation (they're state, not decoration)

**Watch for URL-as-state.** Modals, drawers, active tabs and filter panels are
very often encoded in the query string. Copy the encoding *exactly* — it's
cheap to do and it makes links portable between the original and the clone.

## 2. Capture each page

Screenshot top, then scroll and screenshot again until you hit the footer.
For each page write down:

- **Layout**: column widths, what's sticky, what scrolls independently.
- **Copy**: verbatim. Headings, placeholders, helper text, button labels,
  empty-state sentences. Paraphrased copy is the fastest way to make a clone
  feel wrong.
- **Empty states**: icon, title, description, action. Get these — they're a
  third of the polish and they're easy to miss on a populated account.
- **Loading states**: skeleton shape tells you the component's anatomy. A
  skeleton is a free spec for a component you may not otherwise see populated.
- **Counts and numbers**: exact formatting. `685.9M` vs `686M` is a real bug.

## 3. Open every menu

Dropdowns, popovers, context menus, date pickers, "add filter" menus,
segmented controls. Enumerate every option and its exact label and order.
These are invisible in screenshots and expensive to guess.

Escape can leave a menu stuck — if a popover won't close, navigate away and
come back rather than fighting it.

## 4. Probe the interactions

Click, hover and drag the primary content component. Specifically test:

- Does hovering do something non-obvious? (scrub, preview, reveal controls)
- What is clickable vs what looks clickable?
- What opens a detail view, and does it change the URL?
- Keyboard shortcuts advertised in the UI (`⇧⌘O` next to a nav row).
- What state survives a reload, and what survives navigating to a sibling route.

Note anything surprising in the spec explicitly. These details are what make
the clone feel like the original rather than like a screenshot of it.

## 5. Read the stack

```
read_network_requests({ tabId, limit: 60 })
```
after a fresh navigation. Look for:

- `/_next/static/` → Next.js. `?_rsc=` → App Router with RSC prefetch.
- `clerk.*`, `auth0`, `supabase` → the auth provider.
- `*.hasura.app/v1/graphql`, `convex.cloud`, `/api/trpc` → the data layer.
- A CDN host → where media comes from.

Then pull the design tokens off the live stylesheet:

```js
// javascript_tool — returns the real values, no eyeballing
const out = {};
for (const sheet of document.styleSheets) {
  let rules; try { rules = sheet.cssRules } catch { continue }
  const walk = rs => { for (const r of rs) {
    if (r.style && r.selectorText === ':root')
      for (const p of r.style) if (p.startsWith('--')) out[p] = r.style.getPropertyValue(p).trim();
    if (r.cssRules) walk(r.cssRules);
  }};
  walk(rules);
}
JSON.stringify({ font: getComputedStyle(document.body).fontFamily, vars: out })
```

Repeat with the dark selector (`.dark`, `:root[data-theme="dark"]`) to get the
dark palette. If the values come back as `lab(...)`, set them on a probe element
and read `getComputedStyle` back to convert.

**The `javascript_tool` refuses to return cookies or query strings** — don't
build expressions that include `location.href`; the whole call gets blocked.

## 6. Find the theme control

Check settings for an appearance preference. Three states (Light / Dark /
Auto) is common. Toggle it, screenshot a dense page in dark, **then set it
back**. Note the accent colour — brand colours often swap role in dark mode.

## 7. Note what you couldn't reach

Routes with no data on this account (an empty Boards list hides
`/boards/[id]`), gated features, anything behind a paid tier. Write these in
the spec as **inferred**, and say so again in the final report. Never present
an inferred layout as observed.

---

## Cleanup

Close the tabs you opened (`tabs_close_mcp`). Revert any user preference you
changed.
