# =============================================================================
# Combined single-container build for workshop-api + workshop-cli
# Runs both the Express API (port 4000) and Next.js frontend (port 3000)
# with nginx as reverse proxy on port $PORT (default 8080)
# Clones source repos directly (no submodule dependency)
# =============================================================================

# --- Stage 1: Build the API ---
FROM node:20-alpine AS api-builder

RUN apk add --no-cache git

WORKDIR /build/api

# Cache buster to force fresh clone (update timestamp to pull latest commits)
ARG CACHEBUST=20260421_1920
RUN git clone --depth=1 https://github.com/Aciditik/workshop-api.git .

RUN npm ci

RUN npx prisma generate

RUN npm run build

# --- Stage 2: Build the Frontend ---
FROM node:20-alpine AS frontend-builder

RUN apk add --no-cache git

WORKDIR /build/frontend

# Cache buster to force fresh clone
ARG CACHEBUST=20260421_1920
RUN git clone --depth=1 https://github.com/Aciditik/workshop-cli.git .

RUN npm ci

ARG NEXT_PUBLIC_API_URL=""
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

RUN npm run build

# --- Stage 3: Production image ---
FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    openssl \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- API setup ---
COPY --from=api-builder /build/api/package*.json ./api/
RUN cd api && npm ci --omit=dev

COPY --from=api-builder /build/api/prisma ./api/prisma
RUN cd api && npx prisma generate

COPY --from=api-builder /build/api/dist ./api/dist

# --- Frontend setup ---
COPY --from=frontend-builder /build/frontend/.next/standalone ./frontend
COPY --from=frontend-builder /build/frontend/.next/static ./frontend/.next/static
COPY --from=frontend-builder /build/frontend/public ./frontend/public

# --- Nginx config ---
COPY nginx.conf /etc/nginx/nginx.conf.template

# --- Supervisor config ---
COPY supervisord.conf /etc/supervisord.conf

# --- Startup script and seed ---
COPY start.sh /app/start.sh
COPY seed.js /app/api/seed.js
RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
