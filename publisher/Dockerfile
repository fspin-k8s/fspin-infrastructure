FROM google/cloud-sdk:alpine

ARG release=latest

ENV RELEASE_ID $release

RUN set -x \
       && apk --update add gettext libintl

WORKDIR /opt

COPY . .

RUN set -x \
       && mkdir -p ${RELEASE_ID} \
       && envsubst '${RELEASE_ID}' < "README.template" > "${RELEASE_ID}/README.md" \
       && echo "export RELEASE_ID=${RELEASE_ID}" > release_id

ENTRYPOINT /opt/fspin-publish
