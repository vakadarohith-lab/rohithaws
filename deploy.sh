#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/vakadarohith-lab/rohithaws.git}"
APP_DIR=/opt/rohithaws

sudo apt-get update
sudo apt-get install -y git nginx python3-venv python3-pip

if [ -d "$APP_DIR/.git" ]; then
  sudo git -C "$APP_DIR" pull --ff-only origin main
else
  sudo git clone "$REPOSITORY_URL" "$APP_DIR"
fi

sudo chown -R ubuntu:www-data "$APP_DIR"
sudo -u ubuntu python3 -m venv "$APP_DIR/.venv"
sudo -u ubuntu "$APP_DIR/.venv/bin/pip" install --upgrade pip
sudo -u ubuntu "$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

sudo install -m 0644 "$APP_DIR/flask-app.service" /etc/systemd/system/flask-app.service
sudo tee /etc/nginx/sites-available/flask-app >/dev/null <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sfn /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled/flask-app
sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl enable --now flask-app
sudo systemctl restart nginx
curl --fail http://127.0.0.1/health
