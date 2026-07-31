# AC7 Ride — Component specifications

Every component here exists in `../../frontend/src/components/`. Design and code are meant to stay in step — if you change a spec, change the component.

---

## Button

`components/ui/Button.tsx`

### Variants

| Variant | Background | Text | Use |
|---|---|---|---|
| `primary` | `#8A1538` + brand shadow | White | One per screen. The main action. |
| `secondary` | `#ECECEC` | `#1F1F1F` | Alternative actions |
| `ghost` | Transparent | `#1F1F1F` | Tertiary, toolbars, cancel |
| `danger` | `#EF4444` | White | Destructive — cancel ride, SOS |
| `success` | `#10B981` | White | Rare — confirm going online |

### Sizes

| Size | Height | Padding | Radius | Text |
|---|---|---|---|---|
| `sm` | 36 px | 16 px | 8 px | 14 px |
| `md` | 44 px | 20 px | 12 px | 15 px |
| `lg` | 56 px | 28 px | 16 px | 16 px |

`lg` is the default for anything primary on mobile — it clears the 44 px touch minimum comfortably and is easy to hit one-handed.

### States

| State | Treatment |
|---|---|
| Default | As specified |
| Hover | Primary → `#A31B48`; secondary → `#D1D1D6` |
| Active | Scale `0.98`, primary → `#6E102D` |
| Focus | 2 px maroon ring, 2 px offset |
| Disabled | 40% opacity, no shadow, `not-allowed` cursor |
| Loading | Spinner replaces the leading icon, label stays, `aria-busy` |

**Only one primary button per screen.** Two primaries means neither is primary.

**The label stays visible while loading.** Replacing text with a bare spinner loses context and shifts layout.

---

## Input

`components/ui/Input.tsx`

Height 48 px · radius 12 px · 1 px border `#E5E5E7` · padding 16 px · text 15 px

| State | Border | Notes |
|---|---|---|
| Default | `#E5E5E7` | |
| Hover | `#D1D1D6` | |
| Focus | `#8A1538` + 2 px ring at 20% opacity | |
| Error | `#EF4444` + ring at 20% | Message below, `role="alert"` |
| Disabled | `#E5E5E7`, background `#F5F5F7` | Muted text |

Label sits above at 14 px / 500. Helper text below at 14 px muted. **Error replaces helper text** — never stack both, it doubles the vertical shift when validation fires.

Leading icons at 18 px add 44 px left padding. Trailing slots (password reveal) are 36 px buttons.

---

## Card

`components/ui/Card.tsx`

| Tone | Background | Shadow | Border |
|---|---|---|---|
| `flat` | `#ECECEC` | none | none |
| `raised` | `#FFFFFF` | `card` | none |
| `glass` | `rgba(255,255,255,0.7)` + blur 20px | `lifted` | 1 px white 40% |

Radius 16 px, padding 20 px. `glass` is for surfaces floating over the map.

---

## Sheet

`components/ui/Sheet.tsx`

The primary booking surface.

**Mobile** — pinned to the bottom, full width, top corners 24 px, `sheet` shadow, max height 85vh, scrolls internally. Grab handle 40 × 4 px in `#D1D1D6`, centred, 12 px from top. Bottom padding respects `env(safe-area-inset-bottom)`.

**Desktop (≥1024 px)** — becomes a floating panel: left 16 px, vertically inset 16 px, width 416 px, all corners 24 px, `lifted` shadow, no handle.

Entry: slide up 320 ms on mobile, fade up 280 ms on desktop.

The sheet is **not** a modal — the map behind stays interactive. It renders as a labelled `<section>`, not `role="dialog"`.

---

## Modal

`components/ui/Modal.tsx`

For decisions that must be made: cancel ride, send SOS, top up wallet.

Scrim `rgba(31,31,31,0.25)` + 4 px blur. Panel white, radius 24 px, padding 24 px, `lifted` shadow. Widths — `sm` 384 px, `md` 448 px, `lg` 672 px.

Behaviour: focus trapped, Escape closes, scrim click closes, focus returns to the trigger, body scroll locked. `role="dialog"`, `aria-modal`, labelled by the title.

Footer buttons right-aligned, cancel on the left as `ghost`, confirm on the right.

**Destructive confirmations use `danger`** and say what will happen — "Your driver is already on the way. A cancellation fee may apply."

---

## Toast

`components/ui/Toast.tsx`

Bottom centre on mobile, bottom right on desktop. Max width 384 px. White, radius 16 px, 1 px border, `lifted` shadow.

| Tone | Icon | Colour |
|---|---|---|
| `info` | `Info` | Muted grey |
| `success` | `CheckCircle2` | `#10B981` |
| `error` | `AlertTriangle` | `#EF4444` |

Info and success auto-dismiss after 5 s. **Errors persist** until dismissed — they usually require action.

`role="status"` for info and success, `role="alert"` for errors.

---

## Badge

`components/ui/Badge.tsx`

Pill, 12 px / 600, padding 4 × 10 px. Optional 6 px leading dot.

Ride statuses map as:

| Status | Tone | Label |
|---|---|---|
| `requested` | brand | Finding a driver |
| `accepted` | brand | Driver on the way |
| `in_progress` | success | In progress |
| `completed` | success | Completed |
| `cancelled` | danger | Cancelled |

Backend status strings are never shown raw. `in_progress` is not a phrase anyone says.

---

## Avatar

`components/ui/Avatar.tsx`

Circular. Sizes 32 / 40 / 56 / 80 px. Falls back to initials in white on `#8A1538`.

Decorative avatars beside a visible name are `aria-hidden`. Standalone avatars carry an `alt`.

---

## Skeleton

`components/ui/Skeleton.tsx`

`#ECECEC` base with a white shimmer sweeping left to right over 1.6 s.

**Skeletons must match the shape of the content they replace.** A skeleton that is the wrong height causes a layout jump the moment data lands, which is the exact problem skeletons exist to prevent.

Use for initial loads. Use a spinner for actions in flight.

---

## EmptyState

`components/ui/EmptyState.tsx`

Icon in a 56 px rounded square, title at H4, description at 15 px muted, optional action button. Vertical padding 56 px.

Empty states are invitations, not apologies. "No trips yet — once you take your first ride it will appear here" beats "Nothing found".

Error tone uses a `#EF4444` tint and `role="alert"`, but the copy stays calm and offers a retry.

---

## MapView

`components/map/MapView.tsx`

| Element | Treatment |
|---|---|
| Base map | Custom style — greys, labels muted, POIs off |
| Pickup marker | 14 px white circle, 3.5 px maroon ring |
| Destination marker | 14 px solid maroon, 3 px white ring |
| Driver marker | Rotated arrow, `#1F1F1F`, 2 px white stroke, points along heading |
| Route line | `#8A1538`, 5 px, 90% opacity, rounded caps |
| Traffic | Google's layer, shown once a destination is set |

Viewport fits pickup, destination and route with padding `80 / 60 / 320 / 60` — the large bottom value leaves room for the sheet.

**Markers are mutated in place, never recreated.** Rebuilding overlays on every location frame is what makes tracking screens stutter.

**Without a browser Maps key** the component renders a calm placeholder explaining that the map is unavailable. Everything else keeps working.

---

## PlaceSearch

`routes/rider/components/PlaceSearch.tsx`

ARIA combobox over `/geo/geocode/autocomplete`. Debounced 280 ms, minimum 3 characters, biased toward current position.

Arrow keys move the active option, Enter selects, Escape closes, outside click closes. Results in a dropdown with `lifted` shadow, max height 288 px.

Once selected it collapses to a filled row showing a coloured dot, the label, the address, and a clear button.

Leading dots: pickup is a maroon ring, destination is a solid dark dot — mirroring the map markers so the two read as the same system.

---

## VehicleSelector

`routes/rider/components/VehicleSelector.tsx`

Radio group. Each row: 44 px icon tile, name, capacity, duration, and fare right-aligned in tabular figures.

Selected rows take a maroon border and `#FBF2F5` background. Surge shows as "1.4× busy" beneath the fare in maroon.

**A tier with no estimate shows "Price unavailable", never a guess.** Inventing a fare is worse than admitting the pricing service did not answer.
