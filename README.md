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
