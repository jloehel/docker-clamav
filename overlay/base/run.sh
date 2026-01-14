#!/bin/bash -e

. /opt/base/functions

# Set umask to ensure group write permissions on all created files
# 0002 = files: rw-rw-r--, directories: rwxrwxr-x
umask 0002

DAEMON=clamd
EXEC=$(which $DAEMON)
START_COMMAND="${EXEC}"

FANGFRISCH_CONF="/etc/fangfrisch/fangfrisch.conf"
FANGFRISCH_DB="/var/lib/fangfrisch/db.sqlite"

setup_env() {
    declare -g CLAMDB_ALREADY_EXISTS
    if [ -f "/clamav/data/official/ok" ]; then
        CLAMDB_ALREADY_EXISTS='true'
    fi

    declare -g FANGFRISCH_DB_EXISTS
    if [ -f "${FANGFRISCH_DB}" ]; then
        FANGFRISCH_DB_EXISTS='true'
    fi
}

generate_fangfrisch_config() {
    info "Generating fangfrisch configuration..."
    python3 /opt/fangfrisch/generate_config.py
}

init_fangfrisch_db() {
    if [ -z "${FANGFRISCH_DB_EXISTS:-}" ]; then
        info "Initializing fangfrisch database..."
        fangfrisch --conf "${FANGFRISCH_CONF}" initdb
        info "Fangfrisch database initialized."
    else
        info "Fangfrisch database already exists, skipping initialization."
    fi
}

setup_cron() {
    info "Configuring cronjob..."

    # Fangfrisch cron - every 10 minutes
    cat > "/opt/crontabs/${APP_USERNAME}" << 'CRONTAB'
# Fangfrisch refresh every 10 minutes
*/10 * * * * fangfrisch --conf /etc/fangfrisch/fangfrisch.conf refresh >> /var/log/clamav/fangfrisch.log 2>&1
CRONTAB

    chmod 600 "/opt/crontabs/${APP_USERNAME}"
    info "Crontab configured."
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
    info "Running initial fangfrisch refresh..."
    fangfrisch --conf "${FANGFRISCH_CONF}" refresh || true
    info "Initial fangfrisch refresh completed."
}

# Main
info "Setting up environment..."
setup_env

info "Generating fangfrisch configuration..."
generate_fangfrisch_config

info "Initializing fangfrisch database..."
init_fangfrisch_db

info "Setting up cron..."
setup_cron

info "Updating databases..."
update_official_db
update_unofficial_db

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
    "$crond_bin" -c /opt/crontabs/ &
fi

info "Starting clamd..."
exec ${START_COMMAND}
