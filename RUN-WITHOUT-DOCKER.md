# Running authentication without Docker

Docker has been the obstacle, not the backend. This path removes it entirely.

---

## Why this works

`backend/cmd/auth/main.go` constructs exactly one dependency:

```go
db, err := database.NewPostgresPool(&cfg.Database, cfg.Timeout.DatabaseQueryTimeout)
```

No Redis. No NATS. No Kong. The auth service needs **PostgreSQL and nothing else** — and PostgreSQL is Supabase, which is already live with your tables in it.

So authentication can run as a single Go process talking straight to Supabase.

---

## Steps

### 1. Check Go

```bash
go version
```

If it is missing:

```bash
sudo apt update && sudo apt install -y golang-go
```

Go 1.21+ is required. If Ubuntu ships something older:

```bash
sudo snap install go --classic
```

### 2. Start the auth service

```bash
cd "/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi/backend"
go run ./cmd/auth
```

The first run downloads modules — a few minutes. After that it is seconds.

Success looks like a log line saying the server is listening on `:8080`.

Leave this terminal open.

### 3. Restart the frontend

The proxy target changed, and Vite only reads env files at startup.

In the terminal running Vite: `Ctrl+C`, then:

```bash
npm run dev
```

### 4. Sign in

<http://localhost:3000/login>

```
ghaalabh10@gmail.com
```

You land on `/admin`.

---

## What works, and what does not

| | |
|---|---|
| Register, login, profile | Works |
| Admin dashboard shell | Works |
| Rides, geo, pricing, payments, wallet | **Not served** — those are separate services |

`frontend/.env.development.local` points the proxy at `:8080`, which is the auth service alone. Booking a ride needs `rides-service` and `geo-service` too.

To run those as well, each in its own terminal:

```bash
PORT=8081 go run ./cmd/rides
PORT=8083 go run ./cmd/geo
```

But they need Redis, so Docker returns at that point. For now, authentication is what matters.

---

## Going back to Docker later

Once the daemon runs, edit `frontend/.env.development.local`:

```dotenv
DEV_API_PROXY_TARGET=http://localhost:8000
```

Restart Vite. Everything routes through Kong again and all services are available.

---

## Fixing the Docker daemon, when you want to

The error was:

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

You have `docker.io` from apt, which does not start on its own in WSL.

```bash
sudo systemctl start docker
docker ps
```

If that reports *System has not been booted with systemd*, add to `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Then from PowerShell: `wsl --shutdown`, and reopen the terminal.

**The better option:** Docker Desktop is already installed and running on Windows. Settings → Resources → WSL Integration → enable Ubuntu → Apply & Restart. The daemon then comes from Docker Desktop and starts with Windows — no manual step, ever.

---

## On rewriting the backend

Changing language would not have helped. The Go code never ran — there was no daemon to run it in. The same Docker problem would have blocked Node, Python or anything else packaged the same way.

What is in `backend/` is 356 files across 49 domains with tests, an OpenAPI spec and 24 migrations. It connects to Supabase through `pgx`, which is the standard PostgreSQL driver for Go and has no issue with Supabase — the connection was verified working when the migrations were applied.
