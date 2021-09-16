#!/bin/sh

set -e

ME=$(basename "$0")

echo "$ME: Running cron daemon in background..."
crond

echo "$ME: Streaming cron logs to container logs..."
touch /var/log/cron.log
tail -f /var/log/cron.log &
