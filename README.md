# Workshop Deploy

Single-container deployment for the Tournament Manager app (frontend + API).

## Architecture

- **Frontend**: Next.js (port 3000 internally)
- **API**: Express + Prisma + SQLite (port 4000 internally)
- **Nginx**: Reverse proxy (exposed port, default 8080)
  - `/api/*` → Express API
  - `/*` → Next.js frontend

## Setup

### 1. Clone with submodules

```bash
git clone --recurse-submodules <this-repo-url>
# Or if already cloned:
git submodule update --init --recursive
```

### 2. Local development (docker-compose, separate containers)

```bash
docker compose up --build
```

- Frontend: http://localhost:3000
- API: http://localhost:4000

### 3. Production single-container (local test)

```bash
docker compose -f docker-compose.prod.yml up --build
```

- App: http://localhost:8080

## Auto-deploy with GitHub Actions

When you push to either `workshop-api` or `workshop-cli`, a GitHub Action automatically:
1. Triggers the `workshop-deploy` build workflow via `repository_dispatch`
2. Updates submodules to latest
3. Builds & pushes Docker image to GHCR (`ghcr.io/aciditik/workshop-deploy:latest`)
4. Triggers a Render redeploy (if `RENDER_DEPLOY_HOOK` secret is set)

### Required GitHub setup

1. **Create a Personal Access Token (PAT)**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Create a token with `contents: write` permission on `Aciditik/workshop-deploy`
   - Name it `DEPLOY_PAT`

2. **Add the PAT as a secret in both source repos**:
   - `workshop-cli` → Settings → Secrets → Actions → New secret → `DEPLOY_PAT` = your token
   - `workshop-api` → Settings → Secrets → Actions → New secret → `DEPLOY_PAT` = your token

3. **Add Render deploy hook** (optional, for auto-redeploy on Render):
   - `workshop-deploy` → Settings → Secrets → Actions → New secret → `RENDER_DEPLOY_HOOK` = your Render deploy hook URL

### Manual update

```bash
cd workshop-deploy
git submodule update --remote
git add .
git commit -m "Update submodules"
git push
```

## Deploy to Render (Free)

### Option A: Docker image from GHCR
1. Go to [render.com](https://render.com) → **New** → **Web Service**
2. Select **Deploy an existing image from a registry**
3. Image URL: `ghcr.io/aciditik/workshop-deploy:latest`
4. Add env vars: `JWT_SECRET` (generate), `PORT` = `8080`
5. Enable auto-deploy via deploy hook (copy hook URL → add as `RENDER_DEPLOY_HOOK` secret)

### Option B: Build from repo
1. Go to **New** → **Web Service** → connect `workshop-deploy` repo
2. Set **Runtime** to **Docker**
3. Add env var: `JWT_SECRET` = (generate a random string)

## Deploy to Fly.io (Free)

```bash
fly launch --no-deploy
fly secrets set JWT_SECRET=$(openssl rand -hex 32)
fly deploy
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JWT_SECRET` | Secret for JWT signing | (required) |
| `PORT` | Exposed port | `8080` |
