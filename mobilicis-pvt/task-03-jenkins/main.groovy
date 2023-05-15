pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/ashishworkspace/mobilicis.git'
            }
        }
        stage('Deploy') {
            steps {
                sh 'chmod 400 ./mobilicis-pvt/task-01-terraform/ssh/tmp'
                sh """
                ssh ubuntu@13.232.180.81 -i ./mobilicis-pvt/task-01-terraform/ssh/tmp 'sudo apt update && sudo apt install apache2 -y && sudo systemctl start apache2'
                """
            }
        }
    }
}
