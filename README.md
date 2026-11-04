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