#!/bin/sh

# This script updates the operating system if the OS_FLAVOR is known.

set -eux

echo "OS: ${OS}"
echo "OS_FLAVOR: ${OS_FLAVOR}"

if [ "${OS_FLAVOR}" = "alpine" ]; then
    apk update
fi

if [ "${OS_FLAVOR}" = "opensuse/leap" ] || [ "${OS_FLAVOR}" = "opensuse/tumbleweed" ]; then
    zypper --gpg-auto-import-keys -n ref
    zypper -n up
fi

if [ "${OS_FLAVOR}" = "fedora" ]; then
    dnf -y update
fi

if [ "${OS_FLAVOR}" = "debian" ] || [ "${OS_FLAVOR}" = "ubuntu" ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get upgrade -y
fi
