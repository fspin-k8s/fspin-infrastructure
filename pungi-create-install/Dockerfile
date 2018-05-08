FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add jq

WORKDIR /opt

COPY . .

ENTRYPOINT /opt/fspin-27-x86-64-pungi
