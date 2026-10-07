pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                sh '/usr/bin/docker build -t devops-exam-backend:latest .'
            }
        }
    }
}