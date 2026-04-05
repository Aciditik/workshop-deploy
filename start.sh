#!/bin/sh
set -e

# Use PORT env var from hosting platform (default 8080)
export PORT="${PORT:-8080}"

# Replace the port placeholder in nginx config
sed "s/PORT_PLACEHOLDER/$PORT/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Run Prisma migrations
cd /app/api
DATABASE_URL="file:/app/data/prod.db" npx prisma migrate deploy

# Regenerate Prisma Client to match the migrated schema
DATABASE_URL="file:/app/data/prod.db" npx prisma generate

# Seed admin user if it doesn't exist (run from api directory where node_modules exists)
node /app/api/seed.js

cd /app

# Start all services via supervisor
exec supervisord -c /etc/supervisord.conf
