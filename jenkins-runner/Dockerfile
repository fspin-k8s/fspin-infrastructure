FROM jenkins/inbound-agent:alpine

USER root

RUN set -x && \
    apk --update add jq && \
    LATEST_KUBECTL=$(wget -qO - https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    wget -q https://storage.googleapis.com/kubernetes-release/release/${LATEST_KUBECTL}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

USER jenkins
