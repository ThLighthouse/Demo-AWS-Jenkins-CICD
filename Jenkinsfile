#!/usr/bin.env groovy

pipeline {   
    agent any
    stages {
        stage("test") {
            steps {
                script {
                    echo "Testing the application..."

                }
            }
        }
        stage("build") {
            steps {
                script {
                    echo "Building the application..."
                }
            }
        }

        stage("deploy") {
            steps {
                script {
                    /// def dockerCmd = "docker run -p 3080:3080 -d thlighthouse/demo-app:aws-ec2-1.0"
                    sshagent(credentials: ['ec2-server-key'], executable: '') {
                        sh "ssh -o StrictHostKeyChecking=accept-new \
                        ubuntu@172.31.32.219 \
                        sudo docker ps" /// ${dockerCmd}"
                    }
                }
            }
        }               
    }
} 
