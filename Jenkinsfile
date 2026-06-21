pipeline {
  agent any

  parameters {
    string(name: 'TAG_NAME', defaultValue: 'latest', description: 'Docker image tag to deploy from Docker Hub')
  }

  environment {
    AWS_REGION    = 'us-east-1'
    TERRAFORM_DIR = 'terraform-ecs'
    APPOINTMENT_IMAGE = 'vikash3117/appointmentservice'
    PATIENT_IMAGE     = 'vikash3117/patientservic'
    DOCTOR_IMAGE      = 'vikash3117/doctorservice'
    PORTAL_IMAGE      = 'vikash3117/patient-portal'
  }

  stages {
    stage('Checkout') {
      steps {
        echo '====== Checking out repository ======'
        checkout scm
      }
    }

    stage('Terraform Format') {
      steps {
        echo '====== Formatting Terraform ======'
        dir("${TERRAFORM_DIR}") {
          sh 'terraform fmt -recursive'
        }
      }
    }

    stage('Terraform Init') {
      steps {
        echo '====== Initializing Terraform ======'
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            dir("${TERRAFORM_DIR}") {
              sh '''
                export AWS_REGION=${AWS_REGION}
                export AWS_DEFAULT_REGION=${AWS_REGION}
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                terraform init -input=false
              '''
            }
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        echo '====== Planning ECS Terraform ======'
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            dir("${TERRAFORM_DIR}") {
              sh '''
                export AWS_REGION=${AWS_REGION}
                export AWS_DEFAULT_REGION=${AWS_REGION}
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                terraform plan -out=tfplan -input=false \
                  -var "appointment_image=${APPOINTMENT_IMAGE}" \
                  -var "patient_image=${PATIENT_IMAGE}" \
                  -var "doctor_image=${DOCTOR_IMAGE}" \
                  -var "portal_image=${PORTAL_IMAGE}" \
                  -var "image_tag=${TAG_NAME}"
              '''
            }
          }
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        echo '====== Applying ECS Terraform ======'
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            dir("${TERRAFORM_DIR}") {
              sh '''
                export AWS_REGION=${AWS_REGION}
                export AWS_DEFAULT_REGION=${AWS_REGION}
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                terraform apply -input=false -auto-approve tfplan
              '''
            }
          }
        }
      }
    }

    stage('Show Load Balancer') {
      steps {
        echo '====== ECS Load Balancer DNS ======'
        script {
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            dir("${TERRAFORM_DIR}") {
              sh '''
                export AWS_REGION=${AWS_REGION}
                export AWS_DEFAULT_REGION=${AWS_REGION}
                export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                terraform output -raw lb_dns_name
              '''
            }
          }
        }
      }
    }
  }

  post {
    success {
      echo '✅ ECS/Fargate deployment completed successfully'
    }
    failure {
      echo '❌ ECS/Fargate deployment failed'
    }
  }
}
