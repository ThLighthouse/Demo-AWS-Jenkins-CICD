#!/usr/bin.env groovy

library identifier: 'jenkins-shared-library@master', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://gitlab.com/alisher.khusainov/jenkins-shared-library.git',
    credentialsId: 'gitlab-credentials']
)


pipeline {   
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_NAME = 'thlighthouse/demo-app:java-maven-2.0'
    }

    stages {
        stage("test") {
            steps {
                script {
                    echo "Testing the application..."

                }
            }
        }

        stage('build app') {
            steps {
                echo 'Building Java application...'
                sh 'mvn clean package'
            }
        }

        stage('build image') {
            steps {
                script {
                    echo 'building the docker image...'
                    buildImage(env.IMAGE_NAME)
                    dockerLogin()
                    dockerPush(env.IMAGE_NAME)
                }
            }
        } 

        stage("deploy") {
            steps {
                script {
                    echo "deploying docker image to EC2 server"

                    def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                    def ec2Instance = "ubuntu@172.31.32.219"

                    sshagent(credentials: ['ec2-server-key'], executable: '') {
                        def dockerComposeCmd = "docker compose -f /home/ubuntu/docker-compose.yaml up -d"
                        sh "scp server-cmds.sh ${ec2Instance}:/home/ubuntu/"
                        sh "scp docker-compose.yaml ${ec2Instance}:/home/ubuntu/"
                        sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }
                }
            }
        }               
    }
} 
