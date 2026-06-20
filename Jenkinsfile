pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "appointmentservice:${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'docker.io'
        DB_HOST = 'localhost'
        DB_PORT = '3306'
        DB_NAME = 'appointment_db'
    NODE_ENV = 'test'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Lint') {
      steps {
        sh 'npm run lint'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'npm run test'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${DOCKER_IMAGE} .'
      }
    }

    stage('Push and Deploy') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo "Logging into Docker registry..."
              echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin ${DOCKER_REGISTRY}
              IMAGE=${DOCKER_REGISTRY}/${DOCKER_USER}/${DOCKER_IMAGE}
              docker tag ${DOCKER_IMAGE} ${IMAGE}
              docker push ${IMAGE}

              echo "Stopping any existing container..."
              docker rm -f appointmentservice || true

              echo "Starting container..."
              docker run -d -p 8080:8080 \
                -e DB_HOST=${DB_HOST} \
                -e DB_PORT=${DB_PORT} \
                -e DB_NAME=${DB_NAME} \
                -e NODE_ENV=production \
        success { echo '✅ Appointment Service pipeline completed' }
        failure { echo '❌ Appointment Service pipeline failed' }
    }
}
