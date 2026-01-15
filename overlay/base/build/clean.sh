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
    apt-get autoremove -y --purge
    apt-get clean
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
    rm -rf /var/log/*.log /var/log/apt/*
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
    rm -rf /usr/share/locale/* /usr/share/i18n/*
    # Remove pip cache
    rm -rf /root/.cache/pip
    # Remove Python bytecode
    find /usr -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find /usr -type f -name "*.pyc" -delete 2>/dev/null || true
fi

rm -rf /tmp/*
rm -rf /build
