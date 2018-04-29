FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add jq

WORKDIR /bin

COPY . .

ENTRYPOINT /bin/fspin-27-x86-64-livemedia-creator
