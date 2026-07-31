# AC7 Ride — Design

Design source of truth for the AC7 Ride platform. Everything here is paired with the implementation in `../frontend/src/`.

---

## Structure

```
Design/
├── 01-brand/            Identity — palette, typography, logo, voice
│   └── logo/            Logo files (SVG, PNG, favicon)
│
├── 02-design-system/    The system itself
│   ├── DESIGN-TOKENS.md   Human-readable token reference
│   ├── tokens.json        Machine-readable — import into Figma
│   └── COMPONENTS.md      Every component, its states and rules
│
├── 03-user-flows/       Journeys — rider, driver, admin
│
├── 04-screens/          Screen designs, one folder per role
│   ├── auth/
│   ├── rider/
│   ├── driver/
│   └── admin/
│
├── 05-assets/           Exportable source material
│   ├── icons/
│   ├── images/
│   ├── illustrations/
│   └── fonts/
│
├── 06-prototypes/       Clickable prototypes, motion studies
│
└── 07-handoff/          Developer specifications
```

---

## The one rule

**Design tokens live in code, not in Figma.**

`../frontend/tailwind.config.js` is authoritative. `02-design-system/tokens.json` mirrors it for import into design tools.

When a colour, spacing value or radius changes, it changes in `tailwind.config.js` first, then `tokens.json` is regenerated to match. Never the other way round — otherwise the design file and the running product drift apart, and the product is what users see.

---

## File naming

```
{screen}-{state}-{breakpoint}.{ext}

book-ride-empty-mobile.png
book-ride-destination-selected-desktop.png
track-ride-driver-assigned-mobile.png
login-error-mobile.png
```

Lowercase, hyphens, no spaces. Spaces break shell commands and CI.

---

## Breakpoints

| Name | Width | Design at |
|---|---|---|
| Mobile | 320–767 px | 390 px |
| Tablet | 768–1023 px | 834 px |
| Desktop | 1024 px+ | 1440 px |

Mobile first. The rider app is used one-handed, in a moving vehicle, often in bright sunlight — mobile is the primary case, not a scaled-down desktop.

---

## Before handing anything to development

- [ ] Contrast checked — body text ≥ 4.5:1, large text ≥ 3:1
- [ ] Every interactive element has hover, focus, active and disabled states
- [ ] Touch targets ≥ 44 × 44 px
- [ ] Loading, empty and error states designed — not just the happy path
- [ ] Long text tested (Somali and Arabic strings run longer than English)
- [ ] Tokens used throughout — no one-off hex values
- [ ] Works at 320 px without horizontal scroll
