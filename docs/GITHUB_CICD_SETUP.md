# GitHub delivery projects

## 1. Automatic deployment

`.github/workflows/ci-cd.yml` tests every pull request and deploys after pushes. It promotes `development` to the **development** environment, `testing` to **testing**, and `main` to **production**, using AWS Systems Manager (SSM). Create the three GitHub Environments and add `AWS_DEPLOY_ROLE_ARN` and `DEPLOY_INSTANCE_ID` as environment secrets, plus `AWS_REGION` as an environment variable. The role must be trusted by GitHub OIDC and limited to `ssm:SendCommand` and command-status access for the deployment EC2 instance. The instance must be SSM managed.

## 2. Branch management

Create and publish the promotion branches once:

```bash
git checkout -b development
git push -u origin development
git checkout -b testing main
git push -u origin testing
git checkout main
```

In GitHub **Settings → Branches**, protect `testing` and `main`: require pull requests, one review, and the **Test Flask application** status check; prohibit force pushes. Set `main` as the default branch.

## 3. Webhook notifications

The existing `deploy.sh` already sends an AWS SNS success/failure email for Git clone/pull when configured with `scripts/configure-git-email-notification.sh`. For a GitHub push webhook, run `scripts/github-webhook-receiver.py` on the server with a secret stored outside Git. Place it behind an HTTPS reverse proxy, configure GitHub **Settings → Webhooks** with `application/json`, the same secret, and **Push events**, and point it to `/github-webhook`. It verifies `X-Hub-Signature-256` and only deploys `main` pushes.

## 4. Jenkins alternative

Create a Jenkins Multibranch Pipeline from this repository; it will use `Jenkinsfile`. Add an AWS credential/instance profile with SSM command permissions and a Jenkins secret text credential named `deploy-instance-id`. Configure the GitHub webhook endpoint Jenkins supplies. GitHub Actions and Jenkins are alternative deployment triggers—enable one production deploy path to avoid concurrent deployments.
