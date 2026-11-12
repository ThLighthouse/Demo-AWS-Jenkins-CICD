# AWS Services — CI/CD Deployment to EC2 with Jenkins

A hands-on demo project from the **AWS Services** module of the **TechWorld with Nana DevOps Bootcamp**.

In this project, I continued working with Jenkins and AWS EC2. The goal was to move from running Docker commands manually on a server to deploying an application remotely through a Jenkins Pipeline. I started with a simple `docker run`, then used Docker Compose, and finally added dynamic application versioning and automatic Git commits.

The Java Maven application and initial demo structure were provided as part of the bootcamp. This README describes my own setup, changes, practice, and troubleshooting.

## Technologies used

- AWS EC2, VPC networking, and Security Groups
- Jenkins (Multibranch Pipeline, SSH Agent, Credentials)
- Java, Spring Boot, and Maven
- Docker, Docker Hub, and Docker Compose
- Git, GitHub, and GitLab
- Groovy, Jenkins Shared Library, Bash, SSH, and SCP
- PostgreSQL (as a service in the Compose demo)

## Project setup

I used two Ubuntu EC2 instances in the same AWS VPC:

- **Jenkins server:** Runs Jenkins and builds Docker images.
- **Application server:** Receives deployment commands from Jenkins and runs the application containers.

Jenkins connects to the application server over SSH using its **private IP address**. I configured the application server's Security Group to allow SSH traffic from the Jenkins server's Security Group, rather than opening SSH to the whole internet.

For access from Jenkins, I installed the **SSH Agent** plugin and added the EC2 private key to Jenkins Credentials as `ec2-server-key`.

I also created a **Multibranch Pipeline** connected to this GitHub repository. Each working branch has its own Jenkins job, so I could develop and test the stages separately.

## Part 1 — Deploy a Docker container over SSH

The first step was to make sure Jenkins could execute Docker commands on another EC2 instance.

For this exercise I reused the **React + Node.js** image from my earlier [manual EC2 deployment demo](https://github.com/ThLighthouse/Demo-AWS-EC2-Manual-Deployment):

`thlighthouse/demo-app:aws-ec2-1.0`

The image was already available in Docker Hub. Instead of building it again, I added a `deploy` stage to the Jenkinsfile and used `sshagent` to connect to the application server and run the container:

```bash
docker run -d -p 3080:3080 thlighthouse/demo-app:aws-ec2-1.0
```

The command was executed remotely through SSH, not directly on the Jenkins server. I verified that the container was running on the application EC2 instance and that the React application was accessible in the browser.

One problem I faced was an SSH timeout when connecting to the application instance's public IP. Both servers were in the same VPC, so I switched to the application's **private IP** and allowed SSH from the Jenkins Security Group. That solved the connectivity problem.

I also added the Ubuntu user on the application server to the `docker` group to run Docker commands without `sudo`. I learned that Docker login credentials are user-specific: a login performed with `sudo docker login` does not automatically apply to Docker commands run without `sudo`.

## Part 2 — Deploy the Java application with Docker Compose

In the second part I moved back to the **Java Maven application** and replaced the individual Docker command with Docker Compose.

I installed the Docker Compose v2 plugin on the application server and used the current `docker compose` syntax rather than the older standalone `docker-compose` command.

The repository contains two deployment files:

- `docker-compose.yaml` defines the Java application and a PostgreSQL container.
- `server-cmds.sh` receives the image name and starts the Compose project.

The application image is not hardcoded in Compose. The file uses an environment variable:

```yaml
services:
  java-maven-app:
    image: ${IMAGE}
    ports:
      - "8080:8080"

  postgres:
    image: postgres:15
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=pgpswd
```

The Bash script passes the image name to Compose:

```bash
#!/usr/bin/env bash

export IMAGE=$1
docker compose -f docker-compose.yaml up -d
```

From Jenkins, I used **SCP** to copy both files to the application server, then **SSH** to execute the script with the Docker image name as an argument.

After running the pipeline, Docker Compose created the Java application and PostgreSQL containers on the EC2 instance. In this demo, PostgreSQL runs alongside the application, but the supplied Java code does not configure a database connection.

I ran into another useful issue here: running `docker compose down` manually failed because the `IMAGE` variable was not set in that shell session. During a Jenkins deployment, the Bash script exports the variable before starting Compose. For a manual Compose command, the variable also has to be supplied, for example:

```bash
IMAGE=thlighthouse/demo-app:java-maven-2.0 docker compose down
```

## Part 3 — Dynamic image versions and Git commits

The final part connected the build and deployment steps into one pipeline.

Before this, the Docker image tag was fixed. I changed the pipeline to increment the Maven application version and use that version together with the Jenkins build number as the Docker image tag.

For example, the last successful run changed the application version from `1.1.0-SNAPSHOT` to `1.1.1` and created:

`thlighthouse/demo-app:1.1.1-5`

The pipeline now follows this order:

1. **Increment application version** using the Maven Build Helper and Versions plugins.
2. **Test stage** — currently a placeholder that prints a message; this demo does not have automated tests configured.
3. **Build application** with `mvn clean package`.
4. **Build and push Docker image** to my Docker Hub repository.
5. **Deploy to EC2** with SSH, SCP, and Docker Compose.
6. **Commit version update** by committing the modified `pom.xml` and pushing it back to the same working branch.

I configured the Git author for automated version commits as `Jenkins <jenkins@example.com>`. Jenkins uses GitHub credentials stored in its Credentials store for the push, rather than a token written directly into the repository.

The successful pipeline created the GitHub commit [`0dbe241`](https://github.com/ThLighthouse/Demo-AWS-Jenkins-CICD/commit/0dbe2419c15de67631940dc19d6917db3a2a5cbd) in `aws-cicd-part3` after deploying the new image.

## Jenkins Shared Library

I reused and expanded the [Jenkins Shared Library](https://gitlab.com/alisher.khusainov/jenkins-shared-library) I created in the previous bootcamp module.

The main `Jenkinsfile` keeps the stages visible, while reusable Groovy functions in the library handle the implementation. The pipeline calls functions such as:

- `incrementVersion()` — updates the Maven version and returns the new image name.
- `buildImage()`, `dockerLogin()`, and `dockerPush()` — build and publish the image.
- `deployToEC2()` — copies deployment files and runs Docker Compose on EC2.
- `commitVersion()` — commits the updated `pom.xml` and pushes it to the current branch.

This made the Jenkinsfile shorter and helped me understand the difference between defining a pipeline stage and implementing reusable pipeline logic.

## Issues I worked through

Some of the most useful parts of this demo were troubleshooting issues between different tools:

- **SSH timeout:** Fixed the EC2 Security Group rule and used the private IP for communication inside the VPC.
- **Docker permissions and authentication:** Learned the difference between `docker` and `sudo docker`, including their separate login configurations.
- **Docker Compose installation:** Switched from the standalone download used in the lecture to the Ubuntu Compose v2 package.
- **Compose environment variables:** Learned why `${IMAGE}` has to be set when running Compose manually as well as through Jenkins.
- **Shared Library syntax:** Corrected the `$class: 'GitSCMSource'` configuration after Jenkins failed to load the library.
- **Groovy versus Maven interpolation:** Fixed an error where Groovy tried to evaluate `${parsedVersion...}` before Maven received the command.
- **Dockerfile versioning:** Replaced the hardcoded JAR filename with a version-independent copy pattern, so the Docker build still works after Maven increments the version.

Jenkins also reported a **GitHub commit-status permission warning (HTTP 403)**. This did not block the build or deployment; publishing commit statuses requires separate GitHub token permissions.

One item I have **not verified yet** is the behavior of the GitHub webhook after Jenkins pushes its own version-update commit. No repeated-build loop was observed, but I have not configured Ignore Committer Strategy for this repository, so I am not claiming that loop prevention is in place.

## Branches and project files

I used the following branches to keep the work organized:

- `aws-cicd-part1` — remote deployment of the existing React + Node.js image with `docker run`.
- `aws-cicd-part2` — Java application deployment with Docker Compose and remote shell commands.
- `aws-cicd-part3` — dynamic versioning, automatic Git commits, and Shared Library refactoring.
- `main` — the completed parts are merged here through Pull Requests. Part 3 is kept in its working branch until final review.

The key files are `Jenkinsfile`, `Dockerfile`, `docker-compose.yaml`, `server-cmds.sh`, and `pom.xml`. The reusable Groovy functions are maintained in the separate GitLab Shared Library repository.

## What I learned

This demo helped me connect several topics I had previously practiced separately: Jenkins, Docker, Maven, Git, SSH, AWS networking, and Docker Compose.

The biggest difference from the first EC2 exercise was that I no longer had to log into the application server and deploy the image manually. Jenkins could build a new application version, push the image to Docker Hub, connect to another EC2 instance, update the running container, and commit the version change back to GitHub.

The demo is a learning environment, not a production-ready deployment. The PostgreSQL password is currently an example value in Compose, port `5432` is published on the host, and the `test` stage is still a placeholder. Those would need to be addressed for a real application.

The main result for me was understanding how these pieces fit together and being able to troubleshoot each connection when something failed.

## Screenshots of the results

- Jenkins build: /home/alisher/devops-bootcamp-projects/aws-jenkins-cicd/Screenshot_2026-11-12_21-55-28.png

- The result of the Jenkins build pipeline on EC2 host: /home/alisher/devops-bootcamp-projects/aws-jenkins-cicd/Screenshot_2026-11-12_21-57-06.png