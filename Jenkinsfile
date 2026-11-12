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

    stages {
        stage("incremet app version") {
            steps {
                script {
                    env.IMAGE_NAME = incrementVersion()
                    echo "New image: ${env.IMAGE_NAME}"
                }
            }
        }

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
        
        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable:'PASS', usernameVariable:'USER')]) {
                        sh 'git remote set-url origin https://$USER:$PASS@github.com/ThLighthouse/Demo-AWS-Jenkins-CICD.git'
                        sh 'git add .'
                        sh 'git commit -m "ci:version update"'
                        sh 'git push origin HEAD:main'
                    }
                }
            }
        }             
    }
} 
