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

        stage('deploy') {
            steps {
                script {
                    deployToEC2(env.IMAGE_NAME)
                }
            }
        }
        
        stage('commit version update') {
            steps {
                script {
                    commitVersion()
                }
            }
        }             
    }
} 
