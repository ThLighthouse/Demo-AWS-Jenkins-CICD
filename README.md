# AWS - Services

A hands-on demo project completed during the **AWS - Services** module of the TechWorld with Nana DevOps Bootcamp.

## Technologies used



I created new repository for this modules "https://github.com/ThLighthouse/Demo-AWS-Jenkins-CICD" and configured `Multibranch pipeline` on Jenkins for that repo.

I installed `SSH Agent` plugin and configured ssh credentials for the pipeline. Also configured "deploy" stage on the Jenkinsfile: 

```
stage("deploy") {
            steps {
                script {
                    def dockerCmd = "docker run -p 3080:3080 -d thlighthouse/demo-app:aws-ec2-1.0"
                    sshagent(credentials: ['ec2-server-key'], executable: '') {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@EC2-Intance_URL ${dockerCmd}"
                    }
                }
            }
        }               
```

Also I configured AWS VPC connection between two host Jenkins-server -> Application-server with ssh on port 22 and Security Group ID

For the Second part of the project I follow the next steps:
- Install docker compose on EC2 Instance
- Create `docker compose.yaml` file
- Adjust Jenkinsfile to execute docker compose command on EC2 Instance

I have installed docker-compose-plugin on EC2 Instance with `sudo apt install --no-install-recommends docker-compose-v2 ` command and created `docker-compose.yaml` in the application repositor `/home/alisher/devops-bootcamp-projects/aws-jenkins-cicd/docker-compose.yaml`

After `docker compose plugin` was installed on EC2 Instance, I had configured Jenkinsfile on the repository to copy `docker-compose.yaml` file by Jenkins to the instance automatically on the "deploy" stage. I also added shell script to automate executing linux commands.

```
stage("deploy") {
            steps {
                script {
                    echo "deploying docker image to EC2 server"
                    def shellCmd = "bash ./server-cmds.sh"
                    sshagent(credentials: ['ec2-server-key'], executable: '') {
                        def dockerComposeCmd = "docker compose -f /home/ubuntu/docker-compose.yaml up -d"
                        sh "scp server-cmds.sh ubuntu@172.31.32.219:/home/ubuntu/"
                        sh "scp docker-compose.yaml ubuntu@172.31.32.219:/home/ubuntu/"
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@172.31.32.219 ${shellCmd}"
                    }
                }
            }
        }       
```