#!/bin/sh

# This script installs ClamAV and unofficial signatures

set -eux

clamd_config=""
freshclam_config=""

# ClamAV installation per OS
if [ "${OS_FLAVOR}" = "alpine" ]; then
    clamd_config=/etc/clamav/clamd.conf
    freshclam_config=/etc/clamav/freshclam.conf
    apk add --no-cache \
        clamav \
        clamav-daemon \
        clamav-libunrar \
        freshclam \
        nss_wrapper
fi

if [ "${OS_FLAVOR}" = "opensuse/leap" ]; then
    clamd_config=/etc/clamd.conf
    freshclam_config=/etc/freshclam.conf
    zypper -n ar -f "https://download.opensuse.org/repositories/security/openSUSE_Leap_${OS_VERSION}/security.repo" || true
    zypper --gpg-auto-import-keys -n ref
    zypper -n in clamav
    # Busybox crond Symlink
    if [ -f /usr/bin/busybox ] && [ ! -f /usr/sbin/crond ]; then
        ln -s /usr/bin/busybox /usr/sbin/crond
    fi
fi

if [ "${OS_FLAVOR}" = "debian" ] || [ "${OS_FLAVOR}" = "ubuntu" ]; then
    clamd_config=/etc/clamav/clamd.conf
    freshclam_config=/etc/clamav/freshclam.conf
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install \
        clamav \
        clamav-daemon \
        clamav-freshclam
    # Busybox crond Symlink
    if [ -f /usr/bin/busybox ] && [ ! -f /usr/sbin/crond ]; then
        ln -s /usr/bin/busybox /usr/sbin/crond
    fi
fi

# ClamAV unofficial sigs installation
GIT_REPO="https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs"

mkdir -p /etc/clamav-unofficial-sigs
mkdir -p /var/lib/clamav-unofficial-sigs

curl -fsSL "${GIT_REPO}/${UNOFFICIAL_SIGS_VERSION}/clamav-unofficial-sigs.sh" -o /usr/sbin/clamav-unofficial-sigs.sh
curl -fsSL "${GIT_REPO}/${UNOFFICIAL_SIGS_VERSION}/config/master.conf" -o /etc/clamav-unofficial-sigs/master.conf
curl -fsSL "${GIT_REPO}/${UNOFFICIAL_SIGS_VERSION}/config/user.conf" -o /etc/clamav-unofficial-sigs/user.conf

chmod 755 /usr/sbin/clamav-unofficial-sigs.sh

# Shebang korrigieren
sed -i 's|^#!/usr/bin/env bash|#!/bin/bash|g' /usr/sbin/clamav-unofficial-sigs.sh

# Work directory konfigurieren
sed -i 's|work_dir=".*"|work_dir="/clamav/data/unofficial"|g' /etc/clamav-unofficial-sigs/master.conf

# User konfigurieren
if [ -n "${clamd_config}" ] && [ -f "${clamd_config}" ]; then
    sed -i "s|^User .*|User ${APP_USERNAME}|g" "${clamd_config}" || true
fi

if [ -n "${freshclam_config}" ] && [ -f "${freshclam_config}" ]; then
    sed -i "s|^DatabaseOwner .*|DatabaseOwner ${APP_USERNAME}|g" "${freshclam_config}" || true
fi

# App User erstellen falls nicht vorhanden
if ! id "${APP_USERNAME}" >/dev/null 2>&1; then
    if [ "${OS_FLAVOR}" = "alpine" ]; then
        adduser -D -u "${APP_USER_DEFAULT}" -g "${APP_USERNAME}" "${APP_USERNAME}"
    else
        useradd -r -u "${APP_USER_DEFAULT}" -g 0 -s /sbin/nologin "${APP_USERNAME}" || true
    fi
fi

# Verzeichnisse erstellen und Berechtigungen setzen
mkdir -p /opt/clamav /clamav/data/official /clamav/data/unofficial/configs
mkdir -p /var/log/clamav-unofficial-sigs /var/log/clamav
mkdir -p /opt/crontabs
mkdir -p /run/clamav
ln -sf /run/clamav /var/run/clamav 2>/dev/null || true

chown -R "${APP_USERNAME}":0 \
    /opt/clamav \
    /clamav \
    /var/log/clamav-unofficial-sigs \
    /run/clamav \
    /var/log/clamav \
    /opt/crontabs \
    /etc/clamav-unofficial-sigs

# Set group write permissions and setgid for group inheritance
chmod -R g+rwX \
    /opt/clamav \
    /opt/crontabs \
    /clamav \
    /var/log/clamav-unofficial-sigs \
    /run/clamav \
    /var/log/clamav

# Set setgid bit on directories so new files inherit the group
find /clamav -type d -exec chmod g+s {} \;
find /opt/clamav -type d -exec chmod g+s {} \;
find /var/log/clamav -type d -exec chmod g+s {} \;
find /var/log/clamav-unofficial-sigs -type d -exec chmod g+s {} \;

chmod g+w /run /etc/clamav-unofficial-sigs/user.conf

# Marker für erfolgreiche Installation
touch /opt/clamav/ok
