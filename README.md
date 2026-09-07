# Flask application on AWS EC2

A minimal Flask application deployed by Gunicorn behind Nginx.

## Run locally

```bash
python -m venv .venv
.venv\\Scripts\\Activate.ps1
pip install -r requirements.txt
python app.py
```

Open `http://127.0.0.1:8000` and `http://127.0.0.1:8000/health`.

## Deploy to Ubuntu EC2

The EC2 security group must permit inbound TCP port 80 (and port 22 only from your own IP). Connect to the instance, then run:

```bash
git clone https://github.com/vakadarohith-lab/rohithaws.git
cd rohithaws
chmod +x deploy.sh
./deploy.sh
```

For later releases, push to `main` and run `./deploy.sh` again on the server. The script pulls the current commit, installs requirements, and restarts the service.

## Docker

Build and run the application locally:

```bash
docker build -t rohithdockerr/python-demo:latest .
docker run --rm -d --name python-demo -p 8000:8000 rohithdockerr/python-demo:latest
curl http://localhost:8000/health
```

Push the tested image to Docker Hub:

```bash
docker login
docker push rohithdockerr/python-demo:latest
```

## Ansible deployment to two EC2 managed nodes

From the Ansible control node, create an inventory with the private IP addresses of the two nodes, then run:

```bash
ansible-playbook -i ansible/inventory.ini ansible/deploy-flask-container.yml
```

The playbook installs Docker, pulls `rohithdockerr/python-demo:latest`, and runs it on port 80 on each managed node.

## Git download email notifications

`deploy.sh` sends an SNS email notification after every successful or failed Git clone/pull. It includes the server name, repository, operation, result, and UTC time. The EC2 instance needs an IAM role allowing `sns:Publish` to the configured topic. Configure the topic on the server once:

```bash
export GIT_NOTIFICATION_TOPIC_ARN='arn:aws:sns:ap-south-1:ACCOUNT_ID:TOPIC_NAME'
bash scripts/configure-git-email-notification.sh
```
