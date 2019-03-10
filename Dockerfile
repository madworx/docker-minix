FROM madworx/qemu AS build

MAINTAINER Martin Kjellstrand [https://github.com/madworx]

ARG VER=3.4.0rc6
ARG ISO_URL='http://download.minix3.org/iso/snapshot/minix_R3.4.0rc6-d5e4fc0.iso.bz2'
ARG ISO_HASH='fbf5bc1dad5ce6992412cb5c4c7c061d'
ARG DISK_SIZE=10G
ARG VCS_REF
LABEL org.label-schema.vcs-url="https://github.com/madworx/docker-minix/" \
      org.label-schema.vcs-ref=${VCS_REF} \
      maintainer="Martin Kjellstrand [https://www.github.com/madworx]"

SHELL [ "/bin/bash", "-c" ]

RUN qemu-img create -f qcow2 /minix.qcow2 ${DISK_SIZE}

RUN curl "${ISO_URL}" | tee >(bzip2 -cd > minix.iso) | md5sum -c <(echo "${ISO_HASH}  -")

COPY tools/patch-image.pl tools/report-error.sh tools/common.expect /
RUN apk add --no-cache perl expect
RUN ./patch-image.pl minix.iso

COPY tools/install-minix.expect /
RUN /install-minix.expect ${VER} || /report-error.sh

RUN ssh-keygen -f /root/.ssh/id_rsa -N ''
COPY tools/install-minix-stage2.expect /
RUN /install-minix-stage2.expect ${VER} || /report-error.sh

COPY tools/install-minix-stage3.expect /
RUN /install-minix-stage3.expect ${VER} || /report-error.sh
RUN sed 's#^#localhost,127.0.0.1 #' /tmp/pubkeys.minix > /root/.ssh/known_hosts

RUN mkdir -p /target/root
RUN cp /minix.qcow2              /target/
COPY tools/sshexec.sh            /target/usr/bin/sshexec
COPY tools/docker-entrypoint.sh  /target/
RUN cp -a /root/.ssh             /target/root/

FROM madworx/qemu
ENV SYSTEM_MEMORY=512 \
    SYSTEM_CPUS=1 \
    SSH_PORT=22
EXPOSE 22
COPY --from=build /target /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
