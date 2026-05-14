# Deploy — JobTracker

JobTracker is split into two pieces that deploy independently:

- **Backend** (Rails API) → **Render.com** (free tier, includes PostgreSQL)
- **Frontend** (Vite + React) → **Vercel** (free hobby tier)

Total deploy time: ~15 minutes the first time, fully automatic afterwards (push to `main` → auto-deploy on both).

---

## 1. Backend → Render.com

### Step 1: Create a Render account
- Open https://render.com and sign up with your GitHub account.
- Authorize Render to read your repos when prompted.

### Step 2: Deploy via Blueprint
The repo has a `render.yaml` at the root that provisions FOUR services:

- **`jobtracker-api`** — Rails API (Puma) — the public endpoint
- **`jobtracker-worker`** — Sidekiq worker — runs scraper jobs (Adzuna, ITJobs.pt) on the daily 06:00 UTC cron
- **`jobtracker-redis`** — Redis instance — Sidekiq broker
- **`jobtracker-db`** — PostgreSQL 16

1. In Render, click **New +** → **Blueprint**.
2. Click **Connect a repository** and pick `brunombpereira/job-tracker`.
3. Render reads `render.yaml` and shows the 4 resources. Click **Apply**.
4. Provisioning takes ~5-7 min (database first, then Redis, then web + worker in parallel).

The `bin/render-build` script runs migrations + idempotent seeds on the web service's build, so you get the 7 placeholder offers automatically.

### Step 2b (optional): Activate Adzuna scraper
ITJobs.pt scraping works out of the box (no key). For Adzuna:

1. Register a free app at https://developer.adzuna.com → get APP_ID + APP_KEY.
2. In Render dashboard → service `jobtracker-api` → Environment, set `ADZUNA_APP_ID` and `ADZUNA_APP_KEY`.
3. Repeat for service `jobtracker-worker` (same values).
4. Both services redeploy. The 06:00 UTC cron starts fetching the next day, or trigger manually from the "Procurar" tab in the UI.

### Step 2c: Sidekiq dashboard
Available at `https://jobtracker-api.onrender.com/sidekiq`. Username `admin`, password from `SIDEKIQ_PASSWORD` env var (auto-generated, visible in Render dashboard).

### Step 2d: Lock the API with `API_ACCESS_TOKEN` (do not skip)
The API has no user accounts — it's gated by a single shared secret. **Without it, the deployed API serves everything, including your CV, email and phone, to anyone with the URL.**

1. Generate a token: `ruby -rsecurerandom -e 'puts SecureRandom.hex(24)'`.
2. Service **jobtracker-api** → **Environment** → add `API_ACCESS_TOKEN` with that value.
3. Save (Render redeploys). The frontend now shows a login screen; enter the same token as the password.

Leave it unset only for local development — the API stays open there. The app logs a security warning at boot if it's missing in production.

### Step 3: Note the URL
After the deploy succeeds, the web service has a URL like `https://jobtracker-api.onrender.com`. Copy it.

### Step 4: Set `CORS_ORIGINS` (after you deploy the frontend)
Once the frontend is up on Vercel (see below), come back to Render:

1. Service **jobtracker-api** → **Environment** → **Add Environment Variable**.
2. Key: `CORS_ORIGINS`. Value: your Vercel URL, e.g. `https://job-tracker-ui.vercel.app`. You can pass multiple comma-separated.
3. Save. Render redeploys automatically (~1 min).

### Test it
- Open `https://jobtracker-api.onrender.com/api/v1/offers` in your browser. You should see a JSON array with 7 offers.
- Check `https://jobtracker-api.onrender.com/up` returns HTTP 200 — that's the health check Render polls.

> ⚠️ Free tier spins down after 15 minutes idle. The first request after idle takes ~30 seconds to wake up. That's normal — for portfolio demo it's acceptable, for production upgrade to the Starter plan ($7/month).

---

## 2. Frontend → Vercel

### Step 1: Create a Vercel account
- Open https://vercel.com and sign up with your GitHub account.

### Step 2: Import the repo
1. Click **Add New** → **Project**.
2. Pick `brunombpereira/job-tracker` from the list.
3. **Crucial step — Root Directory**: click **Edit** next to the project root and set it to `frontend`. Vercel will then detect Vite and pre-fill the Build Command (`npm run build`) and Output Directory (`dist`).
4. Open **Environment Variables** and add:
   - `VITE_API_URL` = the Render URL from step 1, with `/api/v1` appended. Example: `https://jobtracker-api.onrender.com/api/v1`
5. Click **Deploy**. ~2 minutes.

### Step 3: Copy the live URL
After deploy, Vercel gives you `https://job-tracker-<random>.vercel.app`. You can rename it later in **Settings → Domains** to something like `job-tracker-ui`.

### Step 4: Go back and finish the CORS config on Render
- Add the Vercel URL to `CORS_ORIGINS` on Render (Step 4 of the backend section).

---

## How updates work after this

Push any commit to `main` on GitHub. Render and Vercel both auto-redeploy. Migrations run automatically via `bin/render-build`.

---

## Troubleshooting

**Frontend loads but shows "Erro a carregar ofertas"**
- The browser's network tab shows a CORS error → `CORS_ORIGINS` on Render is wrong. Update with the exact Vercel URL (no trailing slash).
- The browser's network tab shows a 503 / "service unavailable" → Render free service is asleep. Wait 30s and refresh.

**Render build fails on "could not connect to PostgreSQL"**
- The database service was destroyed (90-day free tier limit) or not yet provisioned. Check the database in Render dashboard, redeploy if needed.

**Vercel build fails with "command not found: vite"**
- Root Directory isn't set to `frontend`. Fix it in **Project → Settings → Root Directory** and redeploy.

**Frontend deploys but loads only blank**
- `VITE_API_URL` is unset or wrong. Fix it in **Project → Settings → Environment Variables** and redeploy (env vars only apply on next build).

**Login screen rejects the password**
- The value entered must match `API_ACCESS_TOKEN` on Render exactly. Re-check the env var, and confirm the service finished redeploying after you set it.
