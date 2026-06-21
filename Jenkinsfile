pipeline {
    agent any

    parameters {
        string(name: 'TAG_NAME', defaultValue: 'latest', description: 'Docker image tag')
    }

    environment {
        AWS_REGION = "ap-south-1"
        TERRAFORM_DIR = "terraform-ecs"

        APPOINTMENT_IMAGE = "vikash3117/appointmentservice"
        PATIENT_IMAGE     = "vikash3117/patientservic"
        DOCTOR_IMAGE      = "vikash3117/doctorservice"
        PORTAL_IMAGE      = "vikash3117/patient-portal"

        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                sh '''
                echo "Workspace structure:"
                pwd
                ls -la
                echo "Terraform directory check:"
                ls -la terraform-ecs || true
                '''
            }
        }

        stage('Terraform Format') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh '''
                    terraform fmt -recursive
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh '''
                    set -e
                    export AWS_DEFAULT_REGION=${AWS_REGION}

                    echo "Running in:"
                    pwd
                    ls -la

                    terraform init -reconfigure -input=false
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh '''
                    terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {

            dir("${TERRAFORM_DIR}") {

                sh """
                set -e
                export AWS_DEFAULT_REGION=${AWS_REGION}

                terraform plan \
                    -input=false \
                    -detailed-exitcode \
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
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {

            dir("${TERRAFORM_DIR}") {
                sh '''
                set -e
                export AWS_DEFAULT_REGION=ap-south-1
                terraform apply -auto-approve tfplan
                '''
            }
        }
    }
}

        stage('Terraform Output') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh '''
                    export AWS_DEFAULT_REGION=${AWS_REGION}

                    terraform output || true
                    terraform output -raw lb_dns_name || true
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Deployment Successful"
        }

        failure {
            echo "Deployment Failed - Check logs above"
        }

        always {
            cleanWs()
        }
    }
}
