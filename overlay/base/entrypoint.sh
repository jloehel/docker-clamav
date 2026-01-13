#!/bin/bash -e

# Set umask to ensure group write permissions on all created files
# 0002 = files: rw-rw-r--, directories: rwxrwxr-x
umask 0002

. /opt/base/functions

print_welcome_page

if [[ "$1" == "/run.sh" ]]; then
    # Determine libnss_wrapper path based on OS
    LIBNSS_WRAPPER_PATH=""
    if [ -f /usr/lib/libnss_wrapper.so ]; then
        LIBNSS_WRAPPER_PATH="/usr/lib/libnss_wrapper.so"
    elif [ -f /usr/lib/x86_64-linux-gnu/libnss_wrapper.so ]; then
        LIBNSS_WRAPPER_PATH="/usr/lib/x86_64-linux-gnu/libnss_wrapper.so"
    elif [ -f /usr/lib/aarch64-linux-gnu/libnss_wrapper.so ]; then
        LIBNSS_WRAPPER_PATH="/usr/lib/aarch64-linux-gnu/libnss_wrapper.so"
    elif [ -f /usr/lib64/libnss_wrapper.so ]; then
        LIBNSS_WRAPPER_PATH="/usr/lib64/libnss_wrapper.so"
    fi

    # NSS Wrapper für rootless Container
    if [ ! $EUID -eq 0 ] && [ -n "$LIBNSS_WRAPPER_PATH" ] && [ -e "$LIBNSS_WRAPPER_PATH" ]; then
        info "Creating NSS wrapper files for ${APP_USERNAME} with $(id -u):$(id -g)"
        echo "${APP_USERNAME}:x:$(id -u):$(id -g):ClamAV user:${CLAMAV_HOME}:/bin/false" > "$NSS_WRAPPER_PWD"
        echo "${APP_USERNAME}:x:$(id -g):" > "$NSS_WRAPPER_GROUP"
        export NSS_WRAPPER_PASSWD="$NSS_WRAPPER_PWD"
        export NSS_WRAPPER_GROUP="$NSS_WRAPPER_GROUP"
        export LD_PRELOAD="$LIBNSS_WRAPPER_PATH"
    fi

    info "Starting ClamAV services..."
fi

# Tini als PID 1 verwenden
tini_bin=$(which tini 2>/dev/null || echo "/sbin/tini")
if [ -x "$tini_bin" ]; then
    exec "$tini_bin" -- "$@"
else
    exec "$@"
fi
