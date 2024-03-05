FROM docker.io/jenkins/inbound-agent:latest-alpine

ENV PACKER_VERSION 1.10.1

USER root

RUN set -x && \
    apk --update add jq rsync findutils wget unzip gettext libintl

RUN set -x && \
    LATEST_KUBECTL=$(wget -qO - https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    wget -q https://storage.googleapis.com/kubernetes-release/release/${LATEST_KUBECTL}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN set -x && \
    wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    chmod +x ./packer && \
    mv ./packer /usr/local/bin/packer && \
    rm packer_${PACKER_VERSION}_linux_amd64.zip

USER jenkins
