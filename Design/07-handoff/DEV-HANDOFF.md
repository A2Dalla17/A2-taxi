# Design → development handoff

---

## Where things live

| Design decision | Implemented in |
|---|---|
| Colour, type, radii, shadows, motion | `frontend/tailwind.config.js` |
| CSS custom properties | `frontend/src/styles/index.css` |
| Components | `frontend/src/components/ui/` |
| Map styling and markers | `frontend/src/lib/googleMaps.ts` |
| Screens | `frontend/src/routes/` |

**`tailwind.config.js` is authoritative.** `../02-design-system/tokens.json` mirrors it for design tools. When they disagree, the code is right.

---

## Using tokens

Always the semantic class, never a literal:

```tsx
// Yes
<div className="bg-brand text-white rounded-card shadow-card">

// No — invisible to the design system, breaks on any palette change
<div style={{ background: '#8A1538' }}>
```

Available: `bg-brand` `bg-brand-hover` `bg-surface` `bg-card` `text-ink` `text-ink-muted` `text-success` `text-danger` `rounded-card` `rounded-sheet` `rounded-pill` `shadow-card` `shadow-lifted` `shadow-brand` `ease-smooth` `animate-fade-up` `animate-sheet-up`.

---

## Non-negotiables

**One primary button per screen.** Everything else is `secondary` or `ghost`.

**Every interactive element needs five states** — default, hover, active, focus, disabled. A design showing only the default state is not finished.

**Loading, empty and error states are part of the design**, not an afterthought for the developer to invent. Most screens spend meaningful time in one of them.

**Touch targets ≥ 44 × 44 px.** Visual size may be smaller if padding makes up the difference.

**Focus rings are never removed** without an equivalent replacement. Keyboard users depend on them.

**Colour is never the only signal.** Pair with an icon or a label.

**No hard-coded hex.** If a colour is missing from the system, add it to the system.

---

## Content rules

Sentence case everywhere. Buttons are verbs. No exclamation marks in system copy. No "please". No "successfully" — the confirmation is the success.

Errors: what happened, then what to do, in one sentence. Never surface a raw exception.

Never show a backend enum to a user. `in_progress` becomes "In progress". `requested` becomes "Finding a driver".

---

## Numbers

Fares, distances, durations and balances use **tabular figures** (`.tabular`) so columns align.

Currency comes from the record's own `currency_code`, not a hard-coded symbol — the backend is multi-currency.

Round everything that reaches the screen. Float artifacts like `12.400000000000002` are a visible bug.

---

## Motion

`ease-smooth` — `cubic-bezier(0.32, 0.72, 0, 1)` — for everything. 150 ms hover, 200 ms fade, 280 ms content, 320 ms sheet.

Buttons scale to `0.98` on press.

Honour `prefers-reduced-motion`. Already handled globally in `styles/index.css`.

---

## Maps

Two separate Google keys, and the distinction matters:

| Key | Scope | Secret? |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Backend — routing, ETA, traffic, geocoding | **Yes** |
| `VITE_GOOGLE_MAPS_BROWSER_KEY` | Browser — tile rendering only | No, but must be referrer-restricted |

Every Google call except tile rendering goes through the Go `maps` and `geo` services, which keeps the privileged key server-side and puts requests behind your own caching and rate limits.

**Design the no-key state.** Without a browser key the map is a placeholder — booking, pricing and tracking still work, and the UI must not look broken.

---

## Backend truths that shape the UI

**Response envelope** — `{ success, data, meta, error, correlation_id }`. The client unwraps `.data`.

**Single access token, no refresh endpoint.** A 401 means sign in again — there is no silent recovery to design around.

**Ride statuses** — `requested`, `accepted`, `in_progress`, `completed`, `cancelled`. No others exist.

**Snake_case on the wire.** `pickup_latitude`, not `pickupLatitude`.

**No mock data anywhere in this codebase.** Where a feature has no endpoint, the API layer throws `NotImplementedError` and the screen says so. Do not design a screen that implies a capability the backend lacks — check `docs/AC7-ARCHITECTURE-AUDIT.md` first.

---

## Review checklist

- [ ] Renders 320 px → 2560 px with no horizontal scroll
- [ ] All five interaction states present
- [ ] Loading, empty and error states designed
- [ ] Contrast ≥ 4.5:1 body, ≥ 3:1 large text
- [ ] Touch targets ≥ 44 px
- [ ] Tokens only, no literals
- [ ] Long strings tested — Somali and Arabic run longer than English
- [ ] Numbers tabular and rounded
- [ ] Copy follows the voice rules
- [ ] Every endpoint the screen needs actually exists
