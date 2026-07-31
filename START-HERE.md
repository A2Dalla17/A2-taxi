# AC7 Ride — how to run it

---

## One command

Open **PowerShell** (not WSL) and run:

```powershell
cd "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi"
.\scripts\start-dev.ps1
```

It checks prerequisites, starts the backend, starts the frontend, and opens the browser.

If PowerShell blocks the script:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

## Just the interface, no backend

```powershell
.\scripts\start-dev.ps1 -FrontendOnly
```

Every screen renders. Anything that needs data — trips, wallet, earnings — will be empty, and login will fail. Useful for reviewing design.

---

## Before the first full run

`backend\.env` must exist with two values filled in.

```powershell
cd backend
copy .env.supabase.example .env
notepad .env
```

Fill in:

| Variable | Where it comes from |
|---|---|
| `DB_PASSWORD` | Supabase dashboard → Settings → Database |
| `JWT_SECRET` | Generate: `openssl rand -base64 48` |

Everything else is already set for your project.

---

## The URL trap

Vite prints three addresses:

```
→ Local:   http://localhost:3000/          ← use this one
→ Network: http://10.255.255.254:3000/     ← WSL gateway, unreachable
→ Network: http://172.28.143.17:3000/      ← WSL internal, unreachable
```

**Always use `localhost`.** The two `Network` addresses belong to the WSL virtual adapter. Chrome on Windows cannot route to them, and you get `ERR_CONNECTION_TIMED_OUT`.

---

## What runs where

| Service | Port | Purpose |
|---|---|---|
| Frontend | 3000 | The app |
| Kong | 8000 | API gateway — every backend call goes through it |
| Redis | 6379 | Cache, rate limiting |
| NATS | 4222 | Event bus |
| Supabase | remote | PostgreSQL |

The dev server proxies `/api`, `/ws` and `/maps` to Kong, so everything is same-origin and CORS never applies.

**Only seven containers start by default.** The platform has seventeen services, but the Supabase free tier allows 60 pooled connections — running all of them exhausts the pool. Add `-AllServices` if you genuinely need the rest.

---

## Current state

| | |
|---|---|
| Frontend | Working — landing, auth, rider, driver screens |
| Supabase | Connected, 16 tables, migrations 1–4 applied |
| Migrations 5–24 | **Not yet applied** |
| Backend | Starts once `backend\.env` exists |

### Finishing the migrations

```powershell
cd backend
$env:SUPABASE_URL = "postgresql://postgres:<password>@db.<SUPABASE_PROJECT_REF>.supabase.co:5432/postgres?sslmode=require"
migrate -path database/migrations -database $env:SUPABASE_URL up
```

Use the **direct** host on port 5432, not the pooler — golang-migrate needs advisory locks.

Login and registration work without this. Safety, 2FA, loyalty and the rest need it.

---

## Routes

| Path | Screen |
|---|---|
| `/` | Landing |
| `/login` · `/register` | Authentication |
| `/app` | Rider home |
| `/app/book` | Booking with map |
| `/app/trips` · `/app/wallet` · `/app/profile` | Rider |
| `/driver` | Driver dashboard |
| `/driver/earnings` | Earnings |

Driver routes require an account with `role: driver`. Choose **Drive** on the register screen.

---

## When something breaks

| Symptom | Cause |
|---|---|
| `ERR_CONNECTION_TIMED_OUT` on `10.255.255.254` | Used a Network URL. Use `localhost:3000`. |
| "Something went wrong on our side" | Backend not running. Check `docker ps`. |
| "Cannot reach AC7 Ride" | Frontend cannot reach Kong. Is port 8000 up? |
| Blank page, spinner forever | Check the browser console. |
| `relation "users" does not exist` | Migrations not applied. |
| Map shows a placeholder | No `VITE_GOOGLE_MAPS_BROWSER_KEY`. Everything else still works. |

Backend logs:

```powershell
docker compose -f deploy/docker-compose.yml logs -f auth-service
```
