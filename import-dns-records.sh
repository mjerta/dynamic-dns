#!/usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Missing arguments."
  echo "Usage: $0 <ZONE_ID> <TOKEN>"
  exit 1
fi

ZONE_ID="$1"
TOKEN="$2"

curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/import \
  -H 'Content-Type: multipart/form-data' \
  -H "Authorization: Bearer $TOKEN" \
  --form 'file=@maartenpostma.nl.txt' \
  --form 'proxied=false'
