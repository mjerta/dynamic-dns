#!/usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Error: Missing arguments."
  echo "Usage: $0 <DOMAIN> <ZONE_ID> <TOKEN>"
  exit 1
fi

DOMAIN="$1"
ZONE_ID="$2"
TOKEN="$3"

# Optional: basic domain format check
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Error: DOMAIN '$DOMAIN' does not look valid."
  exit 1
fi

curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  | jq -r --arg name "$DOMAIN" '.result[] | select(.name == $name) | .id'
