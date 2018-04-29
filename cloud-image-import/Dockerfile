FROM google/cloud-sdk:alpine

ENV PACKER_VERSION 1.2.2

RUN set -x \
       && apk --update add wget xz

WORKDIR /bin

COPY . .

ENTRYPOINT /bin/fspin-import-image
