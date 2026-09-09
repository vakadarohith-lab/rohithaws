pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('Test') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          python3 -m venv .ci-venv
          .ci-venv/bin/pip install -r requirements.txt
          .ci-venv/bin/python -c "from app import app; assert app.test_client().get('/health').status_code == 200"
        '''
      }
    }
    stage('Deploy production') {
      when { branch 'main' }
      steps {
        withCredentials([string(credentialsId: 'deploy-instance-id', variable: 'INSTANCE_ID')]) {
          sh '''#!/usr/bin/env bash
            set -euo pipefail
            command_id=$(aws ssm send-command --instance-ids "$INSTANCE_ID" --document-name AWS-RunShellScript --parameters 'commands=["cd /opt/rohithaws && sudo ./deploy.sh"]' --query 'Command.CommandId' --output text)
            aws ssm wait command-executed --command-id "$command_id" --instance-id "$INSTANCE_ID"
          '''
        }
      }
    }
  }
}
