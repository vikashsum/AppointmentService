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
