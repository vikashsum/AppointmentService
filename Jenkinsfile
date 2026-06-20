pipeline {
  agent any

  parameters {
    string(name: 'TAG_NAME', defaultValue: 'latest', description: 'Docker image tag to push (e.g. tagname)')
  }

  environment {
    DOCKER_IMAGE = "appointmentservice:${BUILD_NUMBER}"
    DOCKER_REGISTRY = 'docker.io'
    DOCKER_REPO = 'vikash3117/appointmentservice'
    REPO_URL = 'https://github.com/vikashsum/AppointmentService.git'
    TERRAFORM_DIR = 'terraform'
    K8S_DIR = 'deployment/k8s'
    EKS_CLUSTER_NAME = 'appointmentservice-eks-cluster'
    AWS_REGION = 'us-east-1'
  }

  stages {
    stage('Checkout') {
      steps {
        echo '====== Checking out repository ======'
        git branch: 'main', url: "${REPO_URL}"
      }
    }

    stage('Build') {
      steps {
        echo '====== Building Docker image ======'
        sh 'docker build -t ${DOCKER_IMAGE} .'
        sh 'docker images | grep appointmentservice'
      }
    }

    stage('Push') {
      steps {
        echo '====== Pushing to Docker Hub ======'
        script {
          withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo "Logging into Docker Hub..."
              echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
              
              echo "Tagging image..."
              IMAGE=${DOCKER_REPO}:${TAG_NAME}
              docker tag ${DOCKER_IMAGE} ${IMAGE}

              echo "Pushing image to Docker Hub..."
              docker push ${IMAGE}

              echo "Image pushed successfully: ${IMAGE}"
            '''
          }
        }
      }
    }

    stage('Terraform Init') {
      steps {
        echo '====== Initializing Terraform ======'
        dir("${TERRAFORM_DIR}") {
          sh 'terraform init -input=false'
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        echo '====== Planning Terraform ======'
        dir("${TERRAFORM_DIR}") {
          sh 'terraform plan -out=tfplan -input=false'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        echo '====== Applying Terraform ======'
        dir("${TERRAFORM_DIR}") {
          sh 'terraform apply -input=false -auto-approve tfplan'
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        echo '====== Deploying to EKS ======'
        script {
          withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            sh '''
              export AWS_REGION=${AWS_REGION}
              export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
              export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

              aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
              kubectl apply -k ${K8S_DIR}
              kubectl rollout status deployment/appointmentservice --namespace default --timeout=180s
            '''
          }
        }
      }
    }
  }

  post {
    success {
      echo '✅ Pipeline completed successfully'
    }
    failure {
      echo '❌ Pipeline failed'
    }
  }
}
