FROM madworx/qemu AS build

MAINTAINER Martin Kjellstrand [https://github.com/madworx]
RUN apk add --no-cache perl
RUN curl 'http://download.minix3.org/iso/minix_R3.3.0-588a35b.iso.bz2' | bzip2 -cd > minix.iso

COPY tools/patch-image.pl /
RUN ./patch-image.pl minix.iso
RUN apk add --no-cache expect

COPY tools/install-minix.expect /

RUN echo -en "\0" | dd if=/dev/stdin of=minix.img bs=1024k seek=1024 count=1 \
    && /install-minix.expect \
    && qemu-img convert -f raw -O qcow2 -c /minix.img /minix.qcow2

FROM madworx/qemu
COPY --from=build /minix.qcow2 /
ENTRYPOINT [ "qemu-system-x86_64", "-nographic", "-boot", "c", "-serial", "mon:stdio", "-hda", "/minix.qcow2" ]
