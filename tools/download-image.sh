#!/bin/bash

set -e

MINIX_VERSION="${1:-${MINIX_VERSION}}"

if [ -z "${MINIX_VERSION}" ] ; then
    echo "Unable to detect version to download."
    echo "Either set \$MINIX_VERSION or provide version as first command line argument."
    exit 1
fi

DL_URL="$(awk "\$1 == \"${MINIX_VERSION}\" { print \$3 }" releases.txt)"
ISO_CSUM="$(awk "\$1 == \"${MINIX_VERSION}\" { print \$2 }" releases.txt)"

echo ""
echo "Downloading MINIX version ${MINIX_VERSION}:"
echo "    - URL:       ${DL_URL}"
echo "    - Checksum:  ${ISO_CSUM}"
echo ""

curl "${DL_URL}" | tee >(bzip2 -cd > /minix.iso) | md5sum -c <(echo "${ISO_CSUM}  -")
