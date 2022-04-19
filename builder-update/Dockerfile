FROM google/cloud-sdk:alpine

ENV PACKER_VERSION 1.8.0

RUN set -x \
       && apk --update add wget unzip gettext libintl jq

WORKDIR /bin

RUN wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
 && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
 && rm packer_${PACKER_VERSION}_linux_amd64.zip

WORKDIR /opt

COPY . .

ENTRYPOINT /opt/fspin-packer-snapshot-builder
