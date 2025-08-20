#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Domain is not provided"
  exit 1
fi
DOMAIN="$1"
ZONE_ID="$2"
TOKEN="$3"

# Default values if not provided
DEFAULT_ZONE_ID="$CLOUDFLARE_ZONE_ID"
DEFAULT_TOKEN="$CLOUDFLARE_TOKEN"

# Use defaults if arguments are missing
ZONE_ID="${ZONE_ID:-$DEFAULT_ZONE_ID}"
TOKEN="${TOKEN:-$DEFAULT_TOKEN}"

# Validate required env vars
echo "DOMAIN is $DOMAIN"
echo "TOKEN is $TOKEN"
if [[ -z "$ZONE_ID" || -z "$TOKEN" ]]; then
  echo "Error: ZONE_ID and TOKEN environment variables must be set." >&2
  exit 1
fi

echo 'test'
curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq -r --arg name "$DOMAIN" '.result[] | select(.name == $name) | .id'
