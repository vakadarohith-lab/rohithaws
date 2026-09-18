#!/usr/bin/env bash
set -euo pipefail
APP_DIR=/opt/foodflow
APP_USER=ubuntu
PUBLIC_HOST=ec2-13-201-54-16.ap-south-1.compute.amazonaws.com
sudo apt-get update
sudo apt-get install -y mariadb-server nginx python3-venv python3-pip curl
if ! node --version 2>/dev/null | grep -Eq '^v(2[0-9]|[3-9][0-9])\.'; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
sudo rm -rf "$APP_DIR"
sudo mkdir -p "$APP_DIR"
sudo cp -a /tmp/online-food-delivery/. "$APP_DIR/"
sudo chown -R "$APP_USER:$APP_USER" "$APP_DIR"
DB_PASSWORD=$(openssl rand -base64 30 | tr -dc 'A-Za-z0-9' | head -c 32)
DJANGO_SECRET=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 48)
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS food_delivery_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS 'foodflow'@'localhost' IDENTIFIED BY '${DB_PASSWORD}'; ALTER USER 'foodflow'@'localhost' IDENTIFIED BY '${DB_PASSWORD}'; GRANT ALL PRIVILEGES ON food_delivery_db.* TO 'foodflow'@'localhost'; FLUSH PRIVILEGES;"
printf 'DJANGO_SECRET_KEY=%s\nDJANGO_DEBUG=False\nDB_NAME=food_delivery_db\nDB_USER=foodflow\nDB_PASSWORD=%s\nDB_HOST=127.0.0.1\nDB_PORT=3306\nALLOWED_HOSTS=%s,13.201.54.16,localhost,127.0.0.1\nCORS_ALLOWED_ORIGINS=http://%s\nFRONTEND_URL=http://%s\nFOOD_DELIVERY_TAX_PERCENT=5.00\n' "$DJANGO_SECRET" "$DB_PASSWORD" "$PUBLIC_HOST" "$PUBLIC_HOST" "$PUBLIC_HOST" | sudo tee "$APP_DIR/backend/.env" >/dev/null
sudo chown "$APP_USER:$APP_USER" "$APP_DIR/backend/.env"
sudo chmod 600 "$APP_DIR/backend/.env"
sudo -u "$APP_USER" python3 -m venv "$APP_DIR/backend/venv"
sudo -u "$APP_USER" "$APP_DIR/backend/venv/bin/pip" install --upgrade pip
sudo -u "$APP_USER" "$APP_DIR/backend/venv/bin/pip" install -r "$APP_DIR/backend/requirements.txt" gunicorn
sudo -u "$APP_USER" bash -c "cd '$APP_DIR/backend' && venv/bin/python manage.py migrate --noinput && venv/bin/python manage.py collectstatic --noinput && venv/bin/python manage.py seed_data"
sudo -u "$APP_USER" bash -c "cd '$APP_DIR/frontend' && npm ci && npm run build"
printf '[Unit]\nDescription=FoodFlow Django application\nAfter=network.target mariadb.service\n\n[Service]\nUser=%s\nGroup=%s\nWorkingDirectory=%s/backend\nExecStart=%s/backend/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:8000 food_delivery.wsgi:application\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n' "$APP_USER" "$APP_USER" "$APP_DIR" "$APP_DIR" | sudo tee /etc/systemd/system/foodflow.service >/dev/null
printf 'server {\n    listen 80 default_server;\n    server_name %s 13.201.54.16;\n    root %s/frontend/dist/frontend/browser;\n    index index.html;\n    location /api/ { proxy_pass http://127.0.0.1:8000; proxy_set_header Host $host; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; }\n    location /admin/ { proxy_pass http://127.0.0.1:8000; proxy_set_header Host $host; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; }\n    location /static/ { alias %s/backend/staticfiles/; }\n    location /media/ { alias %s/backend/media/; }\n    location / { try_files $uri $uri/ /index.html; }\n}\n' "$PUBLIC_HOST" "$APP_DIR" "$APP_DIR" "$APP_DIR" | sudo tee /etc/nginx/sites-available/foodflow >/dev/null
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/foodflow /etc/nginx/sites-enabled/foodflow
sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl enable --now foodflow
sudo systemctl restart nginx
curl -fsS http://127.0.0.1/api/schema/ >/dev/null
