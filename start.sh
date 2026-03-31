#!/bin/sh
set -e

# Use PORT env var from hosting platform (default 8080)
export PORT="${PORT:-8080}"

# Replace the port placeholder in nginx config
sed "s/PORT_PLACEHOLDER/$PORT/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Run Prisma migrations
cd /app/api
DATABASE_URL="file:/app/data/prod.db" npx prisma migrate deploy

# Seed admin user if it doesn't exist
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient({ datasources: { db: { url: 'file:/app/data/prod.db' } } });
async function seed() {
  const existing = await prisma.user.findUnique({ where: { email: 'admin@cdf.com' } });
  if (!existing) {
    const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD || '#Pxqz#6Y5z!rxAa$', 10);
    await prisma.user.create({ data: { email: 'admin@cdf.com', password: hash, role: 'admin' } });
    console.log('✓ Admin user created: admin@cdf.com');
  } else {
    console.log('✓ Admin user already exists');
  }
  await prisma.\$disconnect();
}
seed().catch(e => { console.error('Seed error:', e); process.exit(1); });
"

cd /app

# Start all services via supervisor
exec supervisord -c /etc/supervisord.conf
