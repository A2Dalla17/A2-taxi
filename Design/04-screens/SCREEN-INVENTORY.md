# AC7 Ride — Screen inventory

Status of every screen. `Built` means implemented and building cleanly against the real backend.

---

## Auth — `04-screens/auth/`

| Screen | Route | Component | Status |
|---|---|---|---|
| Landing | `/` | `routes/LandingPage.tsx` | Built |
| Login | `/login` | `routes/auth/LoginPage.tsx` | Built |
| Register | `/register` | `routes/auth/RegisterPage.tsx` | Built |
| OTP | `/two-factor` | `routes/auth/TwoFactorPage.tsx` | Built |
| Forgot password | `/forgot-password` | `routes/auth/ForgotPasswordPage.tsx` | Built — backend incomplete |

Auth screens share `AuthShell.tsx`: form on the left, maroon brand panel on the right, panel hidden below 1024 px.

---

## Rider — `04-screens/rider/`

| Screen | Route | Component | Status |
|---|---|---|---|
| Book a ride | `/app` | `routes/rider/BookRidePage.tsx` | Built |
| Track ride | `/app/track/:id` | `routes/rider/TrackRidePage.tsx` | Built |
| Trips | `/app/trips` | `routes/rider/TripsPage.tsx` | Built |
| Wallet | `/app/wallet` | `routes/rider/WalletPage.tsx` | Built |
| Profile | `/app/profile` | `routes/rider/ProfilePage.tsx` | Built |
| Notifications | `/app/notifications` | — | Not started |
| Support | `/app/support` | — | Not started |

### States to design per screen

**Book a ride** — locating; location denied; pickup set, no destination; searching destination; no results; destination set with estimates; surge active; estimates failed; requesting; no Maps key.

**Track ride** — finding a driver; driver assigned with ETA; driver arriving; in progress; completed and awaiting rating; cancelled; socket disconnected; loading; not found.

**Trips** — loading; empty; populated; load failed.

**Wallet** — loading; balance with methods; no payment methods; empty ledger; top-up modal; top-up failed.

---

## Driver — `04-screens/driver/`

| Screen | Route | Status |
|---|---|---|
| Dashboard | `/driver` | Scaffold |
| Incoming request | `/driver` overlay | Not started |
| Active trip | `/driver/trip/:id` | Not started |
| Earnings | `/driver/earnings` | Not started |
| Trip history | `/driver/trips` | Not started |
| Documents | `/driver/documents` | Not started |
| Profile | `/driver/profile` | Not started |

Priority states: offline; online and waiting; incoming request (the critical one — two-second readability); en route to pickup; arrived; trip in progress; completed.

---

## Admin — `04-screens/admin/`

| Screen | Route | Status |
|---|---|---|
| Dashboard | `/admin` | Scaffold |
| Analytics | `/admin/analytics` | Not started |
| Users | `/admin/users` | Not started |
| Drivers | `/admin/drivers` | Not started |
| Live rides | `/admin/rides` | Not started |
| Payments | `/admin/payments` | Not started |
| Promos | `/admin/promos` | Not started |
| Emergencies | `/admin/safety` | Not started |
| Support | `/admin/support` | Not started |

Admin is desktop-first — it is used at a desk, on a large screen, for long sessions. Density matters more than touch comfort here, which inverts the rider app's priorities.

---

## Coverage

| Area | Built | Total | |
|---|---|---|---|
| Auth | 5 | 5 | Complete |
| Rider | 5 | 7 | 71% |
| Driver | 0 | 7 | Scaffold only |
| Admin | 0 | 9 | Scaffold only |
| **Total** | **10** | **28** | **36%** |

---

## Export convention

```
04-screens/rider/book-ride-destination-selected-mobile.png
04-screens/rider/book-ride-surge-active-mobile.png
04-screens/driver/dashboard-incoming-request-mobile.png
04-screens/admin/analytics-overview-desktop.png
```

Mobile at 390 px, tablet at 834 px, desktop at 1440 px. Export at 2×.
