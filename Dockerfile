# =============================================================================
# Combined single-container build for workshop-api + workshop-cli
# Runs both the Express API (port 4000) and Next.js frontend (port 3000)
# with nginx as reverse proxy on port $PORT (default 8080)
# =============================================================================

# --- Stage 1: Build the API ---
FROM node:20-alpine AS api-builder

WORKDIR /build/api

COPY workshop-api/package*.json ./
RUN npm ci

COPY workshop-api/prisma ./prisma
RUN npx prisma generate

COPY workshop-api/tsconfig.json ./
COPY workshop-api/src ./src
RUN npm run build

# --- Stage 2: Build the Frontend ---
FROM node:20-alpine AS frontend-builder

WORKDIR /build/frontend

COPY workshop-cli/package*.json ./
RUN npm ci

COPY workshop-cli/ .

# At build time, the API will be served from the same origin via nginx proxy
# so we use a relative-ish URL that nginx will route
ARG NEXT_PUBLIC_API_URL=""
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

RUN npm run build

# --- Stage 3: Production image ---
FROM node:20-alpine

RUN apk add --no-cache nginx supervisor

WORKDIR /app

# --- API setup ---
COPY workshop-api/package*.json ./api/
RUN cd api && npm ci --omit=dev

COPY workshop-api/prisma ./api/prisma
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

# --- Startup script ---
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Data directory for SQLite
RUN mkdir -p /app/data

EXPOSE 8080

CMD ["/app/start.sh"]
