#!/usr/bin.env groovy

pipeline {   
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_NAME = 'thlightouse/demo-app:java-maven-1.0'
    }

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
                    echo "deploying docker image to EC2 server"

                    def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                    
                    sshagent(credentials: ['ec2-server-key'], executable: '') {
                        def dockerComposeCmd = "docker compose -f /home/ubuntu/docker-compose.yaml up -d"
                        sh "scp server-cmds.sh ubuntu@172.31.32.219:/home/ubuntu/"
                        sh "scp docker-compose.yaml ubuntu@172.31.32.219:/home/ubuntu/"
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@172.31.32.219 ${shellCmd}"
                    }
                }
            }
        }               
    }
} 
