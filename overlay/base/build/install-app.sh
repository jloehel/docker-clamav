#!/bin/sh

# This script installs ClamAV and fangfrisch

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
        freshclam
fi

if [ "${OS_FLAVOR}" = "opensuse/leap" ]; then
    clamd_config=/etc/clamd.conf
    freshclam_config=/etc/freshclam.conf
    zypper -n ar -f "https://download.opensuse.org/repositories/security/openSUSE_Leap_${OS_VERSION}/security.repo" || true
    zypper --gpg-auto-import-keys -n ref
    zypper -n in clamav python3-pip
    # Busybox crond Symlink
    if [ -f /usr/bin/busybox ] && [ ! -f /usr/sbin/crond ]; then
        ln -s /usr/bin/busybox /usr/sbin/crond
    fi
fi

if [ "${OS_FLAVOR}" = "debian" ] || [ "${OS_FLAVOR}" = "ubuntu" ]; then
    clamd_config=/etc/clamav/clamd.conf
    freshclam_config=/etc/clamav/freshclam.conf
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true

    # Configure dpkg to not ask questions and keep existing configs
    echo 'Dpkg::Options {"--force-confdef";"--force-confold";}' > /etc/apt/apt.conf.d/local

    # Create ucf cache directory (needed by clamav-freshclam postinst)
    mkdir -p /var/lib/ucf/cache

    # Install python3-minimal first to prevent python3-pip pulling full python3
    apt-get -y install --no-install-recommends python3-minimal

    apt-get -y install --no-install-recommends \
        clamav \
        clamav-daemon \
        clamav-freshclam \
        python3-pip

    # Busybox crond Symlink
    if [ -f /usr/bin/busybox ] && [ ! -f /usr/sbin/crond ]; then
        ln -s /usr/bin/busybox /usr/sbin/crond
    fi
fi

# Install fangfrisch and jinja2 from PyPI
pip install --no-cache-dir --break-system-packages fangfrisch jinja2

# Create fangfrisch directories
mkdir -p /etc/fangfrisch
mkdir -p /var/lib/fangfrisch

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
mkdir -p /opt/clamav /clamav/data
mkdir -p /var/log/clamav
mkdir -p /opt/crontabs
mkdir -p /run/clamav
ln -sf /run/clamav /var/run/clamav 2>/dev/null || true

chown -R "${APP_USERNAME}":0 \
    /opt/clamav \
    /clamav \
    /var/lib/fangfrisch \
    /etc/fangfrisch \
    /run/clamav \
    /var/log/clamav \
    /opt/crontabs

# Set group write permissions and setgid for group inheritance
chmod -R g+rwX \
    /opt/clamav \
    /opt/crontabs \
    /clamav \
    /var/lib/fangfrisch \
    /etc/fangfrisch \
    /run/clamav \
    /var/log/clamav

# Set setgid bit on directories so new files inherit the group
find /clamav -type d -exec chmod g+s {} \;
find /opt/clamav -type d -exec chmod g+s {} \;
find /var/log/clamav -type d -exec chmod g+s {} \;
find /var/lib/fangfrisch -type d -exec chmod g+s {} \;

chmod g+w /run

# Marker für erfolgreiche Installation
touch /opt/clamav/ok
