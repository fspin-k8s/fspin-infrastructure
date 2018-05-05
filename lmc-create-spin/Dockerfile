FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add jq gettext libintl

WORKDIR /opt

COPY . .

RUN set -x \
       && mkdir -p /opt/spins \
       && for SPIN_NAME in workstation xfce soas lxde lxqt cinnamon mate-compiz kde; \
          do export SPIN_NAME=$SPIN_NAME; \
            envsubst '${SPIN_NAME}' < "f27-x86-64-template" > "spins/f27-x86-64-${SPIN_NAME}"; \
            chmod +x "spins/f27-x86-64-${SPIN_NAME}"; \
          done

ENTRYPOINT /opt/fspin-27-x86-64-livemedia-creator
