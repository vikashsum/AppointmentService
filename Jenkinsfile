```groovy
pipeline {
    agent any

    options {
        timestamps()
        ansiColor('xterm')
    }

    parameters {
        string(name: 'TAG_NAME', defaultValue: 'latest', description: 'Docker image tag')
    }

    environment {
        AWS_REGION        = "ap-south-1"
        TERRAFORM_DIR     = "terraform-ecs"

        APPOINTMENT_IMAGE = "vikash3117/appointmentservice"
        PATIENT_IMAGE     = "vikash3117/patientservic"
        DOCTOR_IMAGE      = "vikash3117/doctorservice"
        PORTAL_IMAGE      = "vikash3117/patient-portal"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "====== Checking out repository ======"
                checkout scm
            }
        }

        stage('Terraform Format') {
            steps {
                echo "====== Terraform Format ======"
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform fmt -recursive'
                }
            }
        }

        stage('Verify AWS Credentials') {
            steps {
                echo "====== Verifying AWS Credentials ======"

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    sh '''
                    export AWS_REGION=${AWS_REGION}
                    export AWS_DEFAULT_REGION=${AWS_REGION}

                    echo "AWS CLI Version"
                    aws --version

                    echo ""
                    echo "AWS Configure List"
                    aws configure list

                    echo ""
                    echo "Checking AWS Identity..."
                    aws sts get-caller-identity
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {

                echo "====== Terraform Init ======"

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh '''
                        export AWS_REGION=${AWS_REGION}
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform init -input=false
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {

                echo "====== Terraform Validate ======"

                dir("${TERRAFORM_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {

                echo "====== Terraform Plan ======"

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh '''
                        export AWS_REGION=${AWS_REGION}
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform plan \
                        -input=false \
                        -out=tfplan \
                        -var="appointment_image=${APPOINTMENT_IMAGE}" \
                        -var="patient_image=${PATIENT_IMAGE}" \
                        -var="doctor_image=${DOCTOR_IMAGE}" \
                        -var="portal_image=${PORTAL_IMAGE}" \
                        -var="image_tag=${TAG_NAME}"
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {

                echo "====== Terraform Apply ======"

                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {

                    dir("${TERRAFORM_DIR}") {

                        sh '''
                        export AWS_REGION=${AWS_REGION}
                        export AWS_DEFAULT_REGION=${AWS_REGION}

                        terraform apply \
                        -input=false \
                        -auto-approve \
                        tfplan
                        '''
                    }
                }
            }
        }

        stage('Show LoadBalancer') {
            steps {

                echo "====== ECS Load Balancer ======"

                dir("${TERRAFORM_DIR}") {

                    sh '''
                    terraform output
                    echo ""
                    echo "LoadBalancer DNS:"
                    terraform output -raw lb_dns_name || true
                    '''
                }
            }
        }
    }

    post {

        success {
            echo "===================================="
            echo "Deployment Successful"
            echo "===================================="
        }

        failure {
            echo "===================================="
            echo "Deployment Failed"
            echo "===================================="
        }

        always {
            cleanWs()
        }
    }
}
```
