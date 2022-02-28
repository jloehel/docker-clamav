#!/bin/sh

set -o errexit

if [ ! -s /data/main.cvd  ];then
    freshclam
fi

if [ ! -s /data/Sanesecurity_spam.yara ];then
    /usr/local/sbin/clamav-unofficial-sigs --force
fi

# Start freshcalm in daemon mode and check 24 times for new updates
freshclam -d --check 24
exec "$@"
