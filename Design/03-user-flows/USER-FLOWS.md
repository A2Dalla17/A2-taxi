# AC7 Ride — User flows

Every step below maps to a real backend endpoint. Nothing here is aspirational.

---

## Rider — booking a ride

```
Open app
  │
  ├─ Not signed in ──→ Login  ──→ POST /auth/login
  │                     └─ No account ──→ Register ──→ POST /auth/register
  │
  ▼
Book screen                      GPS fix → GET /geo/geocode/reverse
  │                              Map     → GET /geo/drivers/nearby  (every 15s)
  │
  ▼
Enter destination                GET /geo/geocode/autocomplete  (debounced 280ms)
  │                              GET /geo/geocode/place
  ▼
Choose vehicle                   GET /ride-types/available
  │                              POST /pricing/bulk-estimate
  │                              POST /maps/route      → distance, ETA, polyline
  │
  ├─ Optional: promo code        included in the estimate call
  │
  ▼
Request ride                     POST /rides
  │
  ▼
Finding a driver                 WebSocket: ride_status_update
  │                              Polling fallback: GET /rides/:id  (10s)
  │
  ├─ No driver found ──→ suggest retry or a different tier
  ├─ Rider cancels   ──→ POST /rides/:id/cancel
  │
  ▼
Driver assigned                  WebSocket: driver_location, driver_eta
  │                              Route redrawn driver → pickup
  │
  ├─ Share trip ──→ POST /safety/share  → public link
  ├─ SOS       ──→ POST /safety/sos
  │
  ▼
Trip in progress                 Route redrawn pickup → destination
  │
  ▼
Completed                        Fare shown
  │
  ▼
Rate the driver                  POST /rides/:id/rate
  │
  ▼
Back to booking
```

### Decisions worth noting

**Pickup is set automatically from GPS**, then reverse-geocoded to an address. If geolocation is denied, the flow continues — the rider types a pickup instead. Denying location must never be a dead end.

**Nearby drivers stop polling once a destination is chosen.** At that point the rider cares about their route, not about ambient cars, and the request is wasted battery.

**Cancellation warns differently by state.** Before a driver is assigned it is free. After assignment it says a fee may apply, because `POST /pricing/cancellation-fee` exists and the backend may charge.

---

## Rider — wallet

```
Wallet                GET /wallet
  │                   GET /wallet/transactions
  │                   GET /payment-methods
  ▼
Add money             Quick amounts 50 / 100 / 200 / 500, or custom
  │
  ▼
Confirm               POST /wallet/topup
  │
  ▼
Balance updated       Cache invalidated, toast confirms
```

---

## Driver — a shift

```
Sign in                          POST /auth/login  (role: driver)
  │
  ▼
Dashboard — offline              GET /driver/status
  │
  ▼
Go online                        POST /driver/status  { is_available: true }
  │                              Location pings begin → POST /geo/location  (5s)
  │
  ▼
Waiting                          GET /driver/rides/available  (8s)
  │
  ▼
Ride request appears             Pickup, destination, distance, fare
  │
  ├─ Decline ──→ back to waiting
  │
  ▼
Accept                           POST /driver/rides/:id/accept
  │
  ▼
Navigate to pickup               Waze or Google Maps deep link
  │
  ▼
Start trip                       POST /driver/rides/:id/start
  │
  ▼
Navigate to destination
  │
  ▼
Complete                         POST /driver/rides/:id/complete
  │
  ▼
Earnings updated                 GET /driver/earnings/summary
  │
  ▼
Waiting  ──or──  Go offline      POST /driver/status  { is_available: false }
```

### Decisions worth noting

**Navigation hands off to Waze or Google Maps** rather than building turn-by-turn in-app. Drivers already trust those tools, and rebuilding navigation badly is worse than not building it.

**Location pings every 5 seconds while online**, and stop entirely when offline. Continuous GPS is the single largest battery cost in a driver app.

**An incoming request must be readable in about two seconds.** A driver may be at a junction. Fare and distance are the largest elements; everything else is secondary.

---

## Auth

```
Register                POST /auth/register     rider or driver
  │                     then POST /auth/login   (register returns no token)
  ▼
Signed in

Login                   POST /auth/login  → { user, token }
  │
  ├─ 2FA enabled ──→ OTP screen ──→ POST /2fa/otp/verify
  │
  ▼
Routed by role          rider → /app · driver → /driver · admin → /admin
```

**Password reset is incomplete.** `POST /2fa/otp/send` supports a `password_reset` type, but no endpoint accepts a new password, and the OTP routes require authentication — so a locked-out user cannot use them. The screen states this plainly and points to support. Closing the gap needs one backend handler.

---

## Error paths

Designed, not left to chance:

| Situation | Behaviour |
|---|---|
| No network | "Cannot reach AC7 Ride. Check your connection." Retry button. |
| Session expired (401) | Session cleared, redirect to login with an explanation |
| Rate limited (429) | "Too many requests. Wait a moment." |
| Server error (5xx) | "Something went wrong on our side." Retry. |
| Location denied | Flow continues; rider types a pickup address |
| No Maps key | Static placeholder; booking, pricing and tracking all still work |
| WebSocket dropped | Reconnects with backoff; 10 s polling covers the gap invisibly |
| No drivers nearby | Empty state suggesting a different tier or waiting |

The principle: **degrade, never dead-end.** A rider who cannot see a map should still be able to book a car.
