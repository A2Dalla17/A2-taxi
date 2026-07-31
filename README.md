# AC7 Ride

Enterprise ride-hailing platform. Go microservices backend, React + TypeScript frontend.

---

## Structure

```
AC7 Taxi/
├── backend/                 Go module — the source of truth
│   ├── cmd/                 17 service entry points (auth, rides, geo, payments, …)
│   ├── internal/            49 domain packages, each handler → service → repository
│   ├── pkg/                 Shared libraries (middleware, models, websocket, config)
│   ├── api/                 OpenAPI spec, Postman collection, API test scripts
│   ├── database/migrations/ 24 golang-migrate migrations
│   ├── test/                Integration test helpers
│   ├── third_party/         Vendored gobreaker (go.mod replace target)
│   ├── go.mod  go.sum
│   ├── Makefile             Build, test, migrate targets
│   └── Dockerfile           Multi-stage, parameterised by SERVICE_NAME
│
├── frontend/                React 18 + TypeScript + Vite + Tailwind
│   ├── src/
│   │   ├── api/             One module per backend domain
│   │   ├── components/      UI primitives and the map canvas
│   │   ├── config/          Environment resolution
│   │   ├── hooks/           React Query bindings, realtime, geolocation
│   │   ├── lib/             HTTP client, session, WebSocket, utilities
│   │   ├── providers/       Auth context
│   │   ├── routes/          auth / rider / driver / admin
│   │   └── styles/
│   └── index.html
│
├── deploy/                  Everything that ships or runs the stack
│   ├── docker-compose.yml           Full stack
│   ├── docker-compose.dev.yml       Development
│   ├── docker-compose.test.yml      CI
│   ├── k8s/                         Kubernetes manifests
│   ├── kong/                        API gateway setup
│   ├── monitoring/                  Prometheus, Grafana
│   ├── observability/               OpenTelemetry collector, Tempo
│   └── cron/  cronjobs/
│
├── config/                  Runtime configuration
├── docs/                    Architecture audit, Supabase runbook, frontend guide
├── scripts/                 Setup, migration and git-hook scripts
├── .github/workflows/       CI and container builds
├── package.json             Workspace root
└── README.md
```

**Why the Go code sits under `backend/` with its own `go.mod`:** the module root moved with the source, so every `github.com/richxcame/ride-hailing/...` import still resolves unchanged. No import rewriting was needed, and none should ever be done.

---

## Quick start

```bash
# 1. Infrastructure — Postgres, Redis, NATS, Kong, observability
npm run stack:up

# 2. Database migrations
npm run db:migrate

# 3. Frontend
npm run install:frontend
npm run dev                 # http://localhost:3000
```

Backend services build individually:

```bash
cd backend
go build ./...              # compile everything
go run ./cmd/auth           # a single service
make help                   # all available targets
```

---

## Architecture

**Backend** — 17 independently deployable Go services behind Kong. Postgres via pgx (primary + read replicas), Redis for caching and rate limiting, NATS as the event bus. Prometheus, OpenTelemetry and Sentry throughout.

Kong routes:

| Route | Service |
|---|---|
| `/api/v1/auth` | Registration, login, profile, JWT issuance |
| `/api/v1/rides` | Ride lifecycle — rider side |
| `/api/v1/driver/rides` | Ride lifecycle — driver side |
| `/api/v1/geo` | Location, nearby drivers, geocoding, H3 surge |
| `/api/v1/payments`, `/api/v1/wallet` | Payments, wallet, payouts |
| `/api/v1/admin` | Admin console |
| `/ws` | WebSocket hub |
| `/maps` | Routing, ETA, traffic (server-side Google key) |

**Authentication** — the Go `auth` service issues its own JWTs carrying `{user_id, email, role}`. Roles are `rider`, `driver`, `admin`, enforced server-side by `middleware.RequireRole`. Tokens are accepted via `Authorization: Bearer` or `?token=` (the latter exists so the browser can authenticate a WebSocket handshake).

**Response envelope** — every endpoint returns:

```json
{ "success": true, "data": {}, "meta": {}, "error": null, "correlation_id": "…" }
```

The frontend HTTP client unwraps `.data` and surfaces `.error.message`.

**Ride lifecycle**

```
requested → accepted → in_progress → completed
     └──────────────────────────────→ cancelled
```

---

## Frontend

React 18, TypeScript (strict), Vite 6, Tailwind 3.4, TanStack Query, React Router.

In development Vite proxies `/api`, `/ws` and `/maps` to Kong on `:8000`, so everything is same-origin and CORS never applies. See `docs/FRONTEND.md`.

**No mock data exists anywhere in this codebase.** Where a feature the product needs has no backend endpoint, the API module throws `NotImplementedError` and the screen says so plainly.

### Design system

| Token | Value | Use |
|---|---|---|
| Background | `#FFFFFF` | Cards, sheets, inputs |
| Secondary | `#F5F5F7` | Page background |
| Cards | `#ECECEC` | Flat panels |
| Brand | `#8A1538` | Primary actions |
| Hover | `#A31B48` | Hover on primary |
| Text | `#1F1F1F` | Body copy |
| Muted | `#6B7280` | Secondary copy |
| Success | `#10B981` | Confirmations |
| Danger | `#EF4444` | Errors |

Inter throughout, rounded cards, glass navigation, soft layered shadows. No orange, no yellow, no bright red beyond the semantic danger token. Motion respects `prefers-reduced-motion`.

---

## Configuration

Two separate environment files, and the distinction matters:

| File | Consumed by | Contains secrets? |
|---|---|---|
| `backend/.env` | Go services | **Yes** — DB password, JWT secret, Stripe key, Google Maps server key |
| `frontend/.env.development.local` | Vite | **No** — every `VITE_*` value is bundled into the browser |

Templates: `backend/.env.example` and `frontend/.env.frontend.example`.

The Google Maps browser key (`VITE_GOOGLE_MAPS_BROWSER_KEY`) is separate from the backend's `GOOGLE_MAPS_API_KEY` and must be HTTP-referrer restricted. Without it the map degrades to a placeholder and everything else keeps working.

---

## Database

Postgres 17. Migrations are golang-migrate, in `backend/database/migrations/`, every one with a matching `.down.sql`.

```bash
cd backend
make migrate-up
make migrate-version
make migrate-create NAME=add_something
```

Supabase setup: see `docs/SUPABASE-SETUP.md`. Note that Supabase supplies Postgres only — Redis and NATS still run separately, and authentication is handled by the Go service, not Supabase Auth.

---

## Documentation

| Document | Contents |
|---|---|
| `docs/AC7-ARCHITECTURE-AUDIT.md` | Full backend map, frontend audit, phased plan |
| `docs/SUPABASE-SETUP.md` | Connecting the backend to Supabase, step by step |
| `docs/FRONTEND.md` | Frontend conventions, design system, realtime |
| `docs/PROJECT-REORGANISATION.md` | What moved during the restructure, and why |
| `backend/api/openapi/openapi.yaml` | API specification |

---

## Status

| Area | State |
|---|---|
| Backend | Complete, unmodified from upstream |
| Auth, session, realtime, API layer | Complete |
| Design system | Complete |
| Maps | Complete, degrades without a browser key |
| Rider journey | Complete — book, estimate, track, trips, wallet, profile |
| Driver app | Scaffold |
| Admin console | Scaffold |
