FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add jq

WORKDIR /opt

COPY . .

ENTRYPOINT /opt/fspin-x86-64-pungi
