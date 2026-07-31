# AC7 Ride — Brand guidelines

---

## Positioning

AC7 Ride is a premium transport service. The feeling to aim for is a business-class airport lounge: quiet, composed, unhurried. Not a discount taxi app, and not a nightclub.

**The product should feel calm.** A rider opens it when they are late, in the rain, or in an unfamiliar city. Every design decision should reduce anxiety, not add stimulation.

| We are | We are not |
|---|---|
| Composed | Loud |
| Precise | Playful |
| Restrained | Decorative |
| Confident | Boastful |
| Warm | Casual |

---

## Colour

The palette is deep maroon on clean white and soft grey. Maroon carries the entire brand identity, which is exactly why it must be used sparingly — a colour used everywhere means nothing.

### Core palette

| Role | Hex | Where it is used |
|---|---|---|
| Background | `#FFFFFF` | Cards, sheets, inputs, modals |
| Secondary background | `#F5F5F7` | Page canvas behind cards |
| Cards | `#ECECEC` | Flat panels, secondary buttons |
| Primary brand | `#8A1538` | Primary buttons, active nav, selected state |
| Hover | `#A31B48` | Hover on primary surfaces |
| Primary text | `#1F1F1F` | Headings and body |
| Muted text | `#6B7280` | Captions, secondary information |
| Success | `#10B981` | Trip complete, driver online, credit |
| Danger | `#EF4444` | Errors, cancellation, SOS |

### Maroon scale

Derived from `#8A1538`, for tints and depth:

| Step | Hex | Use |
|---|---|---|
| 50 | `#FBF2F5` | Selected row background, subtle tint |
| 100 | `#F5DFE6` | Badge background |
| 200 | `#E9BECC` | Borders on tinted surfaces |
| 300 | `#D993A9` | Disabled brand elements |
| 400 | `#C06582` | Chart series 4 |
| 500 | `#A31B48` | Hover |
| 600 | `#8A1538` | **Primary** |
| 700 | `#6E102D` | Pressed |
| 800 | `#520C21` | Dark panels |
| 900 | `#360816` | Deepest — auth panel background |

### The 60–30–10 rule

- **60%** white and light grey — surfaces
- **30%** dark text and neutral greys
- **10%** maroon — actions and emphasis only

If a screen looks maroon-heavy, it is wrong. Count the maroon elements: a booking screen should have roughly one maroon button, one maroon selected state, and one maroon map marker.

### Forbidden

- **Orange and amber** — reads as budget, and clashes with maroon
- **Yellow** — poor contrast on white, cheap association
- **Bright red** — reserved for `#EF4444` danger only; never decorative
- **Blue** — the default of every competitor; we are not another blue app
- **Gradients** on brand surfaces — flat maroon only
- **Pure black** `#000000` — use `#1F1F1F`, which is softer and reads better

### Charts

Charts use a maroon-to-neutral ramp. No categorical rainbow.

```
#8A1538  #A31B48  #C06582  #D993A9  #6B7280  #9CA3AF
```

---

## Typography

**Inter**, throughout. One family, no exceptions.

| Style | Size | Weight | Tracking | Line height |
|---|---|---|---|---|
| Display | 56 px | 700 | −0.03em | 1.05 |
| H1 | 40 px | 700 | −0.025em | 1.15 |
| H2 | 32 px | 600 | −0.02em | 1.2 |
| H3 | 24 px | 600 | −0.015em | 1.3 |
| H4 | 20 px | 600 | −0.01em | 1.4 |
| Body | 16 px | 400 | 0 | 1.6 |
| Body small | 15 px | 400 | 0 | 1.55 |
| Caption | 14 px | 400 | 0 | 1.5 |
| Micro | 12 px | 500 | 0.01em | 1.4 |

**Negative tracking on headings is what makes the type feel considered.** Default letter-spacing at large sizes looks loose and amateur.

**Weights: 400, 500, 600, 700 only.** Never 300 — it fails contrast on mobile in sunlight.

**Numbers use tabular figures** wherever they align in columns — fares, distances, earnings, wallet balances. `font-variant-numeric: tabular-nums`.

**Sentence case everywhere.** "Book a ride", not "Book A Ride". Never ALL CAPS except a single-word badge.

---

## Logo

Files belong in `logo/`. Required exports:

```
ac7-logo-full.svg           Wordmark + mark, horizontal
ac7-logo-mark.svg           Mark alone, square
ac7-logo-full-white.svg     For maroon and dark backgrounds
ac7-logo-mark-white.svg
favicon.svg
app-icon-1024.png           Store submission
```

**Clear space** — minimum padding around the logo equal to the height of the mark. Nothing intrudes.

**Minimum sizes** — mark 24 px, full logo 120 px wide. Below that, use the mark alone.

**Never** stretch, rotate, recolour outside the palette, add effects, or place on a busy photograph without a solid backing shape.

The current placeholder is the letterform "A7" in white on a maroon rounded square — see `../../frontend/src/routes/auth/AuthShell.tsx`. Replace it when final artwork exists.

---

## Surfaces and depth

| Token | Shadow | Use |
|---|---|---|
| `xs` | `0 1px 2px rgba(31,31,31,0.04)` | Subtle lift |
| `sm` | `0 1px 3px + 0 1px 2px` | Inputs |
| `card` | `0 2px 8px + 0 1px 3px` | Cards |
| `lifted` | `0 8px 24px + 0 2px 6px` | Modals, floating panels |
| `sheet` | `0 -8px 32px` | Bottom sheets (upward) |
| `brand` | `0 4px 16px rgba(138,21,56,0.24)` | Primary buttons only |

Shadows are **soft and layered**, never a single hard drop shadow. Two layers — a tight contact shadow plus a diffuse one — is what makes depth read as physical rather than pasted on.

**Radii** — cards `16px`, sheets `24px`, buttons `12px` (medium) / `16px` (large), inputs `12px`, pills full.

**Glass navigation** — `background: rgba(255,255,255,0.7)`, `backdrop-filter: blur(20px) saturate(150%)`. Used on the top bar and mobile tab bar so map content remains partly visible behind.

---

## Motion

**Easing** — `cubic-bezier(0.32, 0.72, 0, 1)` for everything. Fast out, slow settle. It reads as physical rather than mechanical.

| Duration | Use |
|---|---|
| 150 ms | Hover, colour change |
| 200 ms | Fade in, small state change |
| 280 ms | Content entry, fade up |
| 320 ms | Sheet slide up, modal |

Buttons scale to `0.98` on press. That single detail does more for perceived quality than any animation.

**Never animate** for decoration. Every transition must explain a state change or a spatial relationship.

**Respect `prefers-reduced-motion`.** Motion sickness is real, and a rider in a moving car is already susceptible.

---

## Voice

Plain, warm, direct. Explain what happened and what to do next.

| Write | Not |
|---|---|
| "Finding your driver" | "Please wait while we process your request" |
| "That email and password do not match" | "Error: Authentication failed" |
| "Your driver is 3 minutes away" | "ETA: 3 MIN" |
| "Add money" | "Top-up wallet balance" |
| "Cancel ride" | "Cancel" |

**Buttons are verbs.** "Book a ride", "Add money", "Send alert" — never "OK", "Submit", "Continue" where something more specific is true.

**No exclamation marks** in system messages. **No "please"** — the interface is not asking a favour. **No "successfully"** — the confirmation is the success.

Errors say what happened and what to do, in that order, in one sentence.

---

## Accessibility

Non-negotiable, not a later pass.

- Body text contrast ≥ **4.5:1**. `#1F1F1F` on `#FFFFFF` is 15.8:1. `#6B7280` on `#FFFFFF` is 4.83:1 — the muted grey is at the limit, so never use it below 14 px.
- White on `#8A1538` is 9.7:1 — safe.
- Touch targets ≥ **44 × 44 px**.
- Focus rings visible: 2 px maroon with a 2 px background-coloured offset. Never remove an outline without replacing it.
- Colour is never the only signal — pair it with an icon or text label. A colour-blind driver must still read trip status.
- Every icon-only button carries an `aria-label`.
