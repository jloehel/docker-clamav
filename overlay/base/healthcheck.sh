#!/bin/bash -e

# ClamAV daemon health check via TCP

exec 3<>/dev/tcp/127.0.0.1/3310
echo -e "PING" >&3
read -r -u 3 -t 5 response
exec 3>&-

if [ "${response}" = "PONG" ]; then
    exit 0
else
    exit 1
fi
