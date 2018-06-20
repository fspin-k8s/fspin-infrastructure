FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add gettext libintl

WORKDIR /opt

COPY . .

ENTRYPOINT /opt/fspin-publish
