FROM madworx/qemu AS build

MAINTAINER Martin Kjellstrand [https://github.com/madworx]

ARG MINIX_VERSION=3.3.0
ARG DISK_SIZE=10G

ARG VCS_REF
LABEL org.label-schema.vcs-url="https://github.com/madworx/docker-minix/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      maintainer="Martin Kjellstrand [https://www.github.com/madworx]"

SHELL [ "/bin/bash", "-c" ]

COPY releases.txt tools/patch-image.pl tools/report-error.sh tools/common.expect tools/download-image.sh /

RUN /download-image.sh

RUN apk add --no-cache perl expect
RUN ./patch-image.pl minix.iso

RUN qemu-img create -f qcow2 /minix.qcow2 ${DISK_SIZE}

COPY tools/install-minix.expect /
RUN /install-minix.expect "${MINIX_VERSION}" || /report-error.sh

RUN ssh-keygen -f /root/.ssh/id_rsa -N ''
COPY tools/install-minix-stage2.expect /
RUN /install-minix-stage2.expect "${MINIX_VERSION}" || /report-error.sh

COPY tools/install-minix-stage3.expect /
RUN /install-minix-stage3.expect "${MINIX_VERSION}" || /report-error.sh
RUN sed 's#^#localhost,127.0.0.1 #' /tmp/pubkeys.minix > /root/.ssh/known_hosts

RUN mkdir -p /target/root
RUN cp /minix.qcow2              /target/
COPY tools/sshexec.sh            /target/usr/bin/sshexec
COPY tools/docker-entrypoint.sh  /target/
RUN cp -a /root/.ssh             /target/root/
RUN echo "${MINIX_VERSION}"     >/target/minix-version


FROM madworx/qemu

ENV SYSTEM_MEMORY=512 \
    SYSTEM_CPUS=1 \
    SSH_PORT=22

EXPOSE 22

COPY --from=build /target /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
