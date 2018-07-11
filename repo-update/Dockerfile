FROM google/cloud-sdk:alpine

ENV PACKER_VERSION 1.2.4

RUN set -x \
       && apk --update add rsync findutils

WORKDIR /bin

COPY . .

ENTRYPOINT /bin/fspin-update-mirror
