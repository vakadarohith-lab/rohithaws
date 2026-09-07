#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/vakadarohith-lab/rohithaws.git}"
APP_DIR=/opt/rohithaws
NOTIFICATION_CONFIG=/etc/rohithaws/git-notification.env

if [ -r "$NOTIFICATION_CONFIG" ]; then
  # shellcheck disable=SC1090
  source "$NOTIFICATION_CONFIG"
fi

notify_git_operation() {
  local result="$1"
  local repository_name
  local message

  [ -n "${GIT_NOTIFICATION_TOPIC_ARN:-}" ] || return 0
  repository_name="${REPOSITORY_URL%/}"
  repository_name="${repository_name##*/}"
  repository_name="${repository_name%.git}"
  message="Server: $(hostname)\nRepository: ${repository_name}\nOperation: ${GIT_OPERATION}\nResult: ${result}\nDate and time (UTC): $(date --utc '+%Y-%m-%dT%H:%M:%SZ')"

  aws sns publish \
    --region "${AWS_REGION:-ap-south-1}" \
    --topic-arn "$GIT_NOTIFICATION_TOPIC_ARN" \
    --subject "Git ${GIT_OPERATION} ${result}: ${repository_name}" \
    --message "$message" || echo "Git notification could not be sent." >&2
}

sudo apt-get update
sudo apt-get install -y awscli git nginx python3-venv python3-pip

if [ -d "$APP_DIR/.git" ]; then
  GIT_OPERATION=pull
  if ! sudo git -C "$APP_DIR" pull --ff-only origin main; then
    notify_git_operation failed
    exit 1
  fi
else
  GIT_OPERATION=clone
  if ! sudo git clone "$REPOSITORY_URL" "$APP_DIR"; then
    notify_git_operation failed
    exit 1
  fi
fi
notify_git_operation successful

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
