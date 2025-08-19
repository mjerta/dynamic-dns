#!/usr/bin/env bash

DIR_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$DIR_PATH/dynamic-dns.conf"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

echo "$CONFIG_FILE"

for DOMAIN in "${!CLOUDFLARE_DETAILS[@]}"; do
  VALUE="${CLOUDFLARE_DETAILS[$DOMAIN]}"
  IFS=":" read -r ZONE_ID TOKEN <<< "$VALUE"
  echo "Updating $DOMAIN with Zone ID $ZONE_ID"
  if [[ -z "$ZONE_ID" || -z "$TOKEN" ]]; then
    echo "Error: Zone ID or token missing for domain '$DOMAIN'"
    exit 1
  fi
done
