# Savorly Jenkins + Ansible deployment

These assets automate the food-delivery container without changing the existing Flask pipeline.

## Jenkins credentials

Create these credentials in Jenkins:

- `dockerhub-rohithdockerr`: Docker Hub username and access token.
- `food-delivery-ssh-key`: SSH private key for the deployment host.

Copy `ansible/inventory.ini.example` to `ansible/inventory.ini` and add the target host. Configure a Pipeline job to use `food-delivery-ops/Jenkinsfile`.

On `main`, Jenkins validates the static site, builds and smoke-tests the image, pushes `rohithdockerr/food-delivery`, then invokes Ansible to deploy it on port 80.

