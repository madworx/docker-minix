FROM madworx/qemu AS build

MAINTAINER Martin Kjellstrand [https://github.com/madworx]

RUN qemu-img create -f qcow2 /minix.qcow2 1G

RUN curl 'http://download.minix3.org/iso/minix_R3.3.0-588a35b.iso.bz2' | bzip2 -cd > minix.iso
COPY tools/patch-image.pl /
RUN apk add --no-cache perl expect
RUN ./patch-image.pl minix.iso

COPY tools/install-minix.expect /
RUN /install-minix.expect

RUN ssh-keygen -f /root/.ssh/id_rsa -N ''
COPY tools/install-minix-stage2.expect /
RUN /install-minix-stage2.expect

COPY tools/install-minix-stage3.expect /
RUN /install-minix-stage3.expect
RUN sed 's#^#localhost,127.0.0.1 #' /tmp/pubkeys.minix > /root/.ssh/known_hosts

RUN mkdir -p /target/root
COPY tools/sshexec.sh            /target/usr/bin/sshexec
COPY tools/docker-entrypoint.sh  /target/
RUN cp /minix.qcow2              /target/
RUN cp -a /root/.ssh             /target/root/
RUN ls -lhR /target
RUN ls -lh /

FROM madworx/qemu
ENV SYSTEM_MEMORY=512 \
    SYSTEM_CPUS=1 \
    SSH_PORT=22
COPY --from=build /target /
RUN ls -lh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
