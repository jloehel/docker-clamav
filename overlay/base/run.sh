#!/bin/bash -e

. /opt/base/functions

# Set umask to ensure group write permissions on all created files
# 0002 = files: rw-rw-r--, directories: rwxrwxr-x
umask 0002

DAEMON=clamd
EXEC=$(which $DAEMON)
START_COMMAND="${EXEC}"

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        error "Both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

setup_env() {
    file_env 'MALWAREPATROL_RECEIPT_CODE'
    file_env 'MALWAREPATROL_PRODUCT_CODE'
    file_env 'MALWAREPATROL_LIST'
    file_env 'MALWAREEXPERT_SERIAL_KEY'
    file_env 'SECURITEINFO_AUTHORISATION_SIGNATURE'
    file_env 'SECURITEINFO_PREMIUM'

    declare -g CLAMDB_ALREADY_EXISTS
    if [ -f "/clamav/data/official/ok" ]; then
        CLAMDB_ALREADY_EXISTS='true'
    fi

    declare -g UNOFFICIALDB_ALREADY_EXISTS
    if [ -f "/clamav/data/unofficial/ok" ]; then
        UNOFFICIALDB_ALREADY_EXISTS='true'
    fi
}

setup_cron() {
    info "Configuring cronjob..."

    cat >> /etc/clamav-unofficial-sigs/user.conf <<EOF
cron_dir="/opt/crontabs/"
cron_filename="${APP_USERNAME}"
cron_user="${APP_USERNAME}"
EOF

    touch "/opt/crontabs/${APP_USERNAME}"
    /bin/bash /usr/sbin/clamav-unofficial-sigs.sh --install-cron || true
}

configure() {
    info "Configuring unofficial signatures..."

    # WICHTIG: -n prüft ob Variable NICHT leer ist
    if [ -n "${MALWAREPATROL_RECEIPT_CODE:-}" ]; then
        echo "malwarepatrol_receipt_code=\"${MALWAREPATROL_RECEIPT_CODE}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi

    if [ -n "${MALWAREPATROL_PRODUCT_CODE:-}" ]; then
        echo "malwarepatrol_product_code=\"${MALWAREPATROL_PRODUCT_CODE}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi

    if [ -n "${MALWAREPATROL_LIST:-}" ]; then
        echo "malwarepatrol_list=\"${MALWAREPATROL_LIST}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi

    if [ -n "${MALWAREEXPERT_SERIAL_KEY:-}" ]; then
        echo "malwareexpert_serial_key=\"${MALWAREEXPERT_SERIAL_KEY}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi

    if [ -n "${SECURITEINFO_PREMIUM:-}" ]; then
        echo "securiteinfo_premium=\"${SECURITEINFO_PREMIUM}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi

    if [ -n "${SECURITEINFO_AUTHORISATION_SIGNATURE:-}" ]; then
        echo "securiteinfo_authorisation_signature=\"${SECURITEINFO_AUTHORISATION_SIGNATURE}\"" >> /etc/clamav-unofficial-sigs/user.conf
    fi
}

update_official_db() {
    if [ -z "${CLAMDB_ALREADY_EXISTS:-}" ]; then
        info "Downloading official ClamAV database (first run)..."
        freshclam || true
        # Fix permissions - freshclam ignores umask
        chmod -R g+rw /clamav/data/official/ 2>/dev/null || true
        touch /clamav/data/official/ok
    else
        info "Official ClamAV database already exists, skipping initial download."
    fi
}

update_unofficial_db() {
    if [ -z "${UNOFFICIALDB_ALREADY_EXISTS:-}" ]; then
        info "Downloading unofficial signatures (first run)..."
        /usr/sbin/clamav-unofficial-sigs.sh --force || true
        touch /clamav/data/unofficial/ok
    else
        info "Unofficial signatures already exist, skipping initial download."
    fi
}

setup_whitelist() {
    info "Setting up whitelist..."

    whitelist_file="/clamav/data/unofficial/configs/my-whitelist.ign2"
    tracker_file="/clamav/data/unofficial/configs/tracker.txt"

    mkdir -p "$(dirname "$whitelist_file")"
    touch "$whitelist_file"

    # Alte Whitelist-Einträge aus Tracker entfernen
    if [ -f "$whitelist_file" ] && [ -f "$tracker_file" ]; then
        while IFS= read -r line; do
            entry=$(echo "$line" | xargs)
            if [ -n "$entry" ]; then
                sed -i.bak "/${entry}/d" "$tracker_file" 2>/dev/null || true
            fi
        done < "$whitelist_file"
    fi

    # Whitelist zurücksetzen
    echo -n "" > "$whitelist_file"
    echo -n "" > "/clamav/data/official/my-whitelist.ign2" 2>/dev/null || true

    # Whitelist aus Environment Variables generieren
    for var in $(compgen -A variable | grep "^WHITELIST"); do
        if [ -n "${!var}" ]; then
            info "Adding whitelist entry from ${var}: ${!var}"
            echo "${!var}" | /usr/sbin/clamav-unofficial-sigs.sh -w 2>/dev/null || true
        fi
    done
}

# Main
info "Setting up environment..."
setup_env

info "Setting up cron..."
setup_cron

info "Configuring services..."
configure

info "Updating databases..."
update_official_db
update_unofficial_db

info "Setting up whitelist..."
setup_whitelist

info "Starting freshclam daemon (checking 24 times per day)..."
# Create a wrapper script that fixes permissions after each update
cat > /tmp/freshclam-wrapper.sh << 'FRESHCLAM_WRAPPER'
#!/bin/bash
while true; do
    freshclam --checks=1
    # Fix permissions after update - freshclam ignores umask
    chmod -R g+rw /clamav/data/official/ 2>/dev/null || true
    # Sleep for 1 hour (24 checks per day)
    sleep 3600
done
FRESHCLAM_WRAPPER
chmod +x /tmp/freshclam-wrapper.sh
/tmp/freshclam-wrapper.sh &

info "Starting crond..."
crond_bin=$(which crond 2>/dev/null || echo "/usr/sbin/crond")
if [ -x "$crond_bin" ]; then
    $crond_bin -c /opt/crontabs/ &
fi

info "Starting clamd..."
exec ${START_COMMAND}
