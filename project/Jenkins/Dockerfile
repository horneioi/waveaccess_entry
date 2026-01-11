FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release\
        unzip && \ 
    curl -fsSL https://get.docker.com | sh

RUN usermod -aG docker jenkins

USER jenkins