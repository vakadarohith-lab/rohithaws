#!/usr/bin/env bash
set -euo pipefail

PUBLIC_HOST="$1"
PUBLIC_IP="$2"
APP_DIR=/opt/foodflow-containers

cd "$APP_DIR"
DB_PASSWORD=$(openssl rand -base64 30 | tr -dc 'A-Za-z0-9' | head -c 32)
ROOT_PASSWORD=$(openssl rand -base64 30 | tr -dc 'A-Za-z0-9' | head -c 32)
DJANGO_SECRET=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 48)

cat > .env <<ENV
DJANGO_SECRET_KEY=${DJANGO_SECRET}
DB_PASSWORD=${DB_PASSWORD}
MARIADB_ROOT_PASSWORD=${ROOT_PASSWORD}
ALLOWED_HOSTS=${PUBLIC_HOST},${PUBLIC_IP},localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://${PUBLIC_HOST}
FRONTEND_URL=http://${PUBLIC_HOST}
ENV
chmod 600 .env

sudo docker compose build
sudo docker compose up -d
