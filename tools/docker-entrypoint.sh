#! /bin/bash

# Parse command line arguments:
QUIET=0
if [ ! -z "$*" ] ; then
    while [ "$#" -gt 0 ] ; do
        case "$1" in
            -q) QUIET=$(($QUIET+1)) ; shift ;;
            -*) echo "Unknown option \`$1'." ; exit 1 ;;
            *) QUIET=$(($QUIET+1)) ; break ;;
        esac
    done
fi

#
# If we have KVM available, enable it:
#
if dd if=/dev/kvm count=0 >/dev/null 2>&1 ; then
    echo "KVM Hardware acceleration will be used."
    ENABLE_KVM="-enable-kvm"
else
    if [ "${QUIET}" -lt 2 ] ; then
        echo "Warning: Lacking KVM support - slower(!) emulation will be used." 1>&2
        sleep 1
    fi
    ENABLE_KVM=""
fi


#
# Shut down gracefully by connecting to the QEMU monitor and issue the
# shutdown command there.
#
trap "{ echo \"Shutting down gracefully...\" 1>&2 ; \
        ssh root@localhost /sbin/poweroff -d ; wait ; \
        echo \"Will now exit entrypoint.\" 1>&2 ; \
        exit 0 ; }" TERM

#
# Boot up NetBSD by starting QEMU.
#
(
    export QEMU_CMDLINE="-nographic \
                   -monitor telnet:0.0.0.0:4444,server,nowait \
                   -boot c \
                   ${ENABLE_KVM} \
                   -serial mon:stdio \
                   -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9,hostfwd=tcp::${SSH_PORT}-:22 -device e1000,netdev=mynet0 \
                   -hda /minix.qcow2 \
                   -d int,pcall,cpu_reset,unimp,guest_errors -D /tmp/qemu.log \
                   -m ${SYSTEM_MEMORY} -smp ${SYSTEM_CPUS}"
    case "${QUIET}" in
        0) exec -a "MINIX3 [QEMU${ENABLE_KVM}]" qemu-system-x86_64 ;;
        *) exec -a "MINIX3 [QEMU${ENABLE_KVM}]" qemu-system-x86_64 >/dev/null 2>&1 ;;
    esac
) &

if [ ! -z "$*" ] ; then
    /usr/bin/sshexec $*
    exit $?
fi

wait
