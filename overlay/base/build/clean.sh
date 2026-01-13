#!/bin/sh

# This script shrinks and cleans the docker image.

set -eux

if [ "${OS_FLAVOR}" = "alpine" ]; then
    rm -rf /var/cache/apk/* /usr/src/*
fi

if [ "${OS_FLAVOR}" = "opensuse/leap" ] || [ "${OS_FLAVOR}" = "opensuse/tumbleweed" ]; then
    zypper clean -a
fi

if [ "${OS_FLAVOR}" = "fedora" ]; then
    dnf clean all
    rm -rf /var/cache/dnf
fi

if [ "${OS_FLAVOR}" = "debian" ] || [ "${OS_FLAVOR}" = "ubuntu" ]; then
    apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
fi

rm -rf /tmp/*
rm -rf /build
