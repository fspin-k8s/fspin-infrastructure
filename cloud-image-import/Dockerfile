FROM google/cloud-sdk:alpine

RUN set -x \
       && apk --update add wget xz sudo

RUN adduser --disabled-password importuser
RUN echo 'importuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /bin

COPY . .

USER importuser

ENTRYPOINT /bin/fspin-import-image
