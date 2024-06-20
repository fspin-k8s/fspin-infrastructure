FROM docker.io/google/cloud-sdk:alpine

RUN set -x \
       && apk --update add jq gettext libintl

WORKDIR /opt

COPY . .

RUN set -x \
       && mkdir -p /opt/spins \
       && for SPIN_NAME in workstation xfce soas lxde lxqt cinnamon mate-compiz kde i3; \
          do export SPIN_NAME=$SPIN_NAME; \
            envsubst '${SPIN_NAME}' < "fspin-x86-64-template" > "spins/fspin-x86-64-${SPIN_NAME}"; \
            chmod +x "spins/fspin-x86-64-${SPIN_NAME}"; \
          done

ENTRYPOINT /opt/fspin-x86-64-livemedia-creator
