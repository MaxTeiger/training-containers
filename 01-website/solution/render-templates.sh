#!/bin/sh

set -e

ME=$(basename "$0")

TEMPLATE_FILE="/usr/share/nginx/html/index.html"
BACKUP="$TEMPLATE_FILE.bkp"

if [ ! -f "$BACKUP" ]; then
    echo "$ME: Backing up $TEMPLATE_FILE to $BACKUP..."
    cp "$TEMPLATE_FILE" "$BACKUP"
fi

echo "$ME: Injecting environment variables into $TEMPLATE_FILE..."
clamp "$BACKUP" > "$TEMPLATE_FILE"

echo "$ME: Environment variables successfully injected."
