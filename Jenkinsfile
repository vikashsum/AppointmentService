pipeline {
    agent any

    options {
        timestamps()
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        string(
            name: 'TAG_NAME',
            defaultValue: 'latest',
            description: 'Docker image tag'
        )
    }

    environment {

        AWS_REGION = "ap-south-1"

        IMAGE_NAME = "vikash3117/appointmentservice"

        TERRAFORM_DIR = "terraform-ecs"

        APPOINTMENT_IMAGE = "vikash3117/appointmentservice"
        PATIENT_IMAGE     = "vikash3117/patientservic"
        DOCTOR_IMAGE      = "vikash3117/doctorservice"
        PORTAL_IMAGE      = "vikash3117/patient-portal"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "===== Checkout ====="
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "===== Building Docker Image ====="

                sh """
                docker build \
                -t appointmentservice:${BUILD_NUMBER} .

                docker images | grep appointmentservice
                """
            }
        }

        stage('Push Docker Image') {

            steps {

                echo "===== Push Docker Image ====="

                withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh """
                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin

                    docker tag appointmentservice:${BUILD_NUMBER} ${IMAGE_NAME}:${TAG_NAME}

                    docker push ${IMAGE_NAME}:${TAG_NAME}

                    docker logout
                    """
                }
            }
        }

        stage('Verify AWS Credentials') {

            steps {

                echo "===== Verify AWS Credentials ====="

                withCredentials([[
                        \$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    sh """
                    export AWS_DEFAULT_REGION=${AWS_REGION}

                    aws --version

                    aws configure list

                    aws sts get-caller-identity
                    """
                }
            }
        }

        stage('Terraform Format') {

            steps {

                dir("${TERRAFORM_DIR}") {

                    sh "terraform fmt -recursive"

                }

            }

        }

        stage('Terraform Init') {

            steps {

                withCredentials([[
                        \$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh """
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform init -input=false
                        """

                    }

                }

            }

        }

        stage('Terraform Validate') {

            steps {

                dir("${TERRAFORM_DIR}") {

                    sh "terraform validate"

                }

            }

        }

        stage('Terraform Plan') {

            steps {

                withCredentials([[
                        \$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh """
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform plan \
                        -input=false \
                        -out=tfplan \
                        -var="appointment_image=${APPOINTMENT_IMAGE}" \
                        -var="patient_image=${PATIENT_IMAGE}" \
                        -var="doctor_image=${DOCTOR_IMAGE}" \
                        -var="portal_image=${PORTAL_IMAGE}" \
                        -var="image_tag=${TAG_NAME}"
                        """

                    }

                }

            }

        }

        stage('Terraform Apply') {

            steps {

                withCredentials([[
                        \$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh """
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform apply \
                        -auto-approve \
                        tfplan
                        """

                    }

                }

            }

        }

        stage('Show Load Balancer') {

            steps {

                dir("${TERRAFORM_DIR}") {

                    sh """

                    echo "==================================="

                    echo "Application URL"

                    terraform output -raw lb_dns_name || true

                    echo "==================================="

                    """

                }

            }

        }

    }

    post {

        success {

            echo "=================================="

            echo "Deployment Successful"

            echo "=================================="

        }

        failure {

            echo "=================================="

            echo "Deployment Failed"

            echo "=================================="

        }

        always {

            cleanWs()

        }

    }

}
