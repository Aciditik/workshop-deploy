#!/bin/sh
set -e

# Use PORT env var from hosting platform (default 8080)
export PORT="${PORT:-8080}"

# Replace the port placeholder in nginx config
sed "s/PORT_PLACEHOLDER/$PORT/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Run Prisma migrations
cd /app/api
DATABASE_URL="file:/app/data/prod.db" npx prisma migrate deploy
cd /app

# Start all services via supervisor
exec supervisord -c /etc/supervisord.conf
