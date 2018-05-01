FROM google/cloud-sdk:alpine

ARG snapshot=latest

ENV PACKER_VERSION 1.2.2
ENV SNAPSHOT_ID $snapshot

RUN set -x \
       && apk --update add wget unzip gettext libintl

WORKDIR /bin

RUN wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
 && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
 && rm packer_${PACKER_VERSION}_linux_amd64.zip

WORKDIR /opt

COPY . .

RUN set -x \
       && envsubst '${SNAPSHOT_ID}' < "fspin.repo" > "fspin-snapshot.repo" \
       && envsubst '${SNAPSHOT_ID}' < "fspin-repo-not-rawhide-with-source.ks" > "fspin-snapshot-repo-not-rawhide-with-source.ks" \
       && envsubst '${SNAPSHOT_ID}' < "fspin-27-x86-64-builder.json" > "fspin-snapshot-27-x86-64-builder.json" \
       && echo "export SNAPSHOT_ID=${SNAPSHOT_ID}" > snapshot_id \
       && echo "export SPIN_ID=`echo ${SNAPSHOT_ID}|awk -F- '{print $1$2$3}'`" >> snapshot_id

ENTRYPOINT /bin/packer build -force fspin-snapshot-27-x86-64-builder.json
