FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add rsync findutils

WORKDIR /bin

COPY . .

ENTRYPOINT /bin/fspin-update-mirror
