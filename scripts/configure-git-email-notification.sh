#!/usr/bin/env bash
# Run once on the EC2 server after attaching an IAM role with sns:Publish.
set -euo pipefail

: "${GIT_NOTIFICATION_TOPIC_ARN:?Set the SNS topic ARN before running this script.}"
AWS_REGION="${AWS_REGION:-ap-south-1}"

sudo install -d -m 0755 /etc/rohithaws
sudo tee /etc/rohithaws/git-notification.env >/dev/null <<EOF
GIT_NOTIFICATION_TOPIC_ARN=${GIT_NOTIFICATION_TOPIC_ARN}
AWS_REGION=${AWS_REGION}
EOF
sudo chmod 0644 /etc/rohithaws/git-notification.env
