withEnv([
  'AWS_DEFAULT_REGION=ap-south-1',
  'DEPLOY_INSTANCE_ID=i-0f7144e96cbc9d7fa',
  'DEPLOY_AZ=ap-south-1a',
  'DEPLOY_PUBLIC_IP=35.154.234.70',
  'DOCKER_NAMESPACE=rohithdockerr/python-demo',
  'JENKINS_ASSETS=/opt/foodflow-jenkins-assets'
]) {
  stage('Checkout') {
    git branch: 'main', url: 'https://github.com/ravitejacmr/online-food-delivery.git'
  }

  stage('Build and push API') {
    sh '''
      cp "$JENKINS_ASSETS/backend/Dockerfile" backend/Dockerfile
      cp "$JENKINS_ASSETS/backend/docker-entrypoint.sh" backend/docker-entrypoint.sh
      cp "$JENKINS_ASSETS/frontend/Dockerfile" frontend/Dockerfile
      cp "$JENKINS_ASSETS/frontend/nginx.conf" frontend/nginx.conf
      cp "$JENKINS_ASSETS/docker-compose.yml" docker-compose.yml
      cp "$JENKINS_ASSETS/ansible-playbook.yml" ansible-playbook.yml
      docker build -t $DOCKER_NAMESPACE:api backend
    '''
    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_TOKEN')]) {
      sh '''
        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
        docker push $DOCKER_NAMESPACE:api
        docker logout
      '''
    }
    sh 'docker image rm $DOCKER_NAMESPACE:api || true'
  }

  stage('Build and push web') {
    sh 'docker build -t $DOCKER_NAMESPACE:web frontend'
    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_TOKEN')]) {
      sh '''
        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
        docker push $DOCKER_NAMESPACE:web
        docker logout
      '''
    }
    sh 'docker image rm $DOCKER_NAMESPACE:web || true'
  }

      stage('Deploy with Ansible') {
        sh 'docker system prune -af'
        sh '''
      rm -f deploy_key deploy_key.pub inventory.runtime.ini
      ssh-keygen -q -t ed25519 -N '' -f deploy_key
      aws ec2-instance-connect send-ssh-public-key \
        --instance-id "$DEPLOY_INSTANCE_ID" \
        --availability-zone "$DEPLOY_AZ" \
        --instance-os-user ubuntu \
        --ssh-public-key file://deploy_key.pub
      printf '[foodflow_nodes]\n%s public_ip=%s\n\n[foodflow_nodes:vars]\nansible_user=ubuntu\nansible_ssh_private_key_file=%s/deploy_key\n' \
        "$DEPLOY_PUBLIC_IP" "$DEPLOY_PUBLIC_IP" "$WORKSPACE" > inventory.runtime.ini
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.runtime.ini ansible-playbook.yml
      rm -f deploy_key deploy_key.pub inventory.runtime.ini
    '''
  }
}
