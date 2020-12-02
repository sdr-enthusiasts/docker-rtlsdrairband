#!/usr/bin/env bash

# This script will test syslog
# It is used for s6-notifyoncheck in service start scripts to bring things up in order

echo "Syslog is up!" | socat - UNIX-CLIENT:/dev/log > /dev/null 2>&1
exit $?