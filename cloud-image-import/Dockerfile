FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add wget xz

WORKDIR /bin

COPY . .

ENTRYPOINT /bin/fspin-import-image
