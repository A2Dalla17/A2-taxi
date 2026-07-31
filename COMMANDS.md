# AC7 Ride — every command, in order

> **Never paste real secrets into this file.** It is tracked by git and the
> repository is public. Placeholders like `<DB_PASSWORD>` are deliberate —
> the real values live in `backend/.env`, which is git-ignored. If you need
> them, open that file locally.



---

# A · Run locally (right now)

Two terminals. Both stay open.

### Terminal 1 — backend

```bash
cd "/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi/backend" && PORT=8080 go run ./cmd/auth
```

Wait for `Connected to database` and `Server starting {"port": "8080"}`.

### Terminal 2 — frontend

```bash
cd "/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi/frontend" && npm run dev
```

Then open **http://localhost:3000** — not the `172.x` or `10.x` addresses Vite prints.

Sign in: `ghaalabh10@gmail.com`

---

# B · Deploy (permanent, works with the laptop off)

Run these in **PowerShell**, in order. Each block is one paste.

## 1 · Install the tools

```powershell
iwr https://fly.io/install.ps1 -useb | iex
npm i -g vercel
```

Close and reopen PowerShell so `fly` is on the PATH.

## 2 · Sign in

```powershell
fly auth signup
vercel login
```

Both open a browser. Free, email only.

## 3 · Deploy the backend

```powershell
cd "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi\backend"
fly launch --no-deploy
```

Answers: app name **ac7-ride-auth** · region **lhr** · Postgres **No** · Redis **No**

```powershell
fly secrets set DB_PASSWORD="<DB_PASSWORD>"
fly secrets set JWT_SECRET="<JWT_SECRET>"
fly deploy
```

Verify:

```powershell
curl https://ac7-ride-auth.fly.dev/healthz
```

Expect `{"status":"healthy","service":"auth-service",...}`.

## 4 · Deploy the frontend

```powershell
cd "..\frontend"
"VITE_API_BASE_URL=https://ac7-ride-auth.fly.dev`nVITE_WS_BASE_URL=wss://ac7-ride-auth.fly.dev`nVITE_DEFAULT_MAP_LAT=2.0469`nVITE_DEFAULT_MAP_LNG=45.3182`nVITE_DEFAULT_CURRENCY=USD`nVITE_GOOGLE_MAPS_BROWSER_KEY=" | Out-File -Encoding utf8 .env.production
vercel --prod
```

Answers: set up and deploy **Y** · framework **Vite** · build `npm run build` · output `dist`

Note the URL it prints, e.g. `https://ac7-ride.vercel.app`.

## 5 · Let them talk

Replace the URL with the one Vercel gave you:

```powershell
cd "..\backend"
fly secrets set CORS_ORIGINS="https://ac7-ride.vercel.app"
```

Wait 30 seconds for the restart.

## 6 · Test properly

Turn the laptop off. Open the Vercel URL on your phone. Sign in.

---

# C · After a change

```powershell
# Backend
cd "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi\backend"; fly deploy

# Frontend
cd "C:\Users\hassa\OneDrive\Documents\A2 Projects\Taxi App\AC7 Taxi\frontend"; vercel --prod
```

---

# D · When something breaks

```powershell
fly logs                 # live backend logs
fly status               # is the machine up
fly secrets list         # names only, never values
fly apps restart ac7-ride-auth
```

| Symptom | Cause |
|---|---|
| `fly` not recognised | Reopen PowerShell after installing |
| Build fails | You are not in `backend/` |
| Health check never passes | Wrong `DB_PASSWORD` — check `fly logs` |
| CORS error in the console | `CORS_ORIGINS` must match the Vercel URL exactly |
| 404 on refresh at `/admin/users` | `vercel.json` missing from `frontend/` |
| Login 500 | Supabase project paused — resume it in the dashboard |

---

# E · Database

Migrations 6, 8–10, 12–18, 20–24 are still outstanding. Login and the admin
console work without them; safety, 2FA and loyalty need them.

```bash
cd "/mnt/c/Users/hassa/OneDrive/Documents/A2 Projects/Taxi App/AC7 Taxi/backend"
migrate -path database/migrations \
  -database "postgresql://postgres.<SUPABASE_PROJECT_REF>:<DB_PASSWORD>@aws-1-eu-west-2.pooler.supabase.com:5432/postgres?sslmode=require" up
```

If `migrate` is missing:

```bash
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
export PATH=$PATH:$(go env GOPATH)/bin
```
