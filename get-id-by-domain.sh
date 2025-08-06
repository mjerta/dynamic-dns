#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Domain is not provided"
  exit 1
fi
DOMAIN="$1"

# Validate required env vars
if [[ -z "$CLOUDFLARE_ZONE_ID" || -z "$CLOUDFLARE_TOKEN" ]]; then
  echo "Error: CLOUDFLARE_ZONE_ID and CLOUDFLARE_TOKEN environment variables must be set." >&2
  exit 1
fi

curl "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" | jq -r --arg name "$DOMAIN" '.result[] | select(.name == $name) | .id'
