#!/bin/sh

set -e

ME=$(basename "$0")

echo "$ME: Counting posts..."
LATEST="$(curl -s https://xkcd.com/info.0.json | jq .num)"

echo "$ME: Found $LATEST posts, picking one at random..."
NUM="$(shuf -i "1-$LATEST" -n 1)"

echo "$ME: Finding image URL for post $NUM..."
IMG_URL="$(curl -s "https://xkcd.com/$NUM/info.0.json" | jq -r .img)"

echo "$ME: Downloading $IMG_URL..."
wget "$IMG_URL" -O /usr/share/nginx/html/image.png

echo "$ME: Image downloaded."
