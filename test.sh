#!/usr/bin/env bash
DIR_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$DIR_PATH/dynamic-dns.conf"
#
# Function to log messages with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

echo "$CONFIG_FILE"

# Read arguments
RECORD_TYPE=${1:-}
RECORD_TTL=${2:-}
RECORD_PROXIED=${3:-}
RECORD_COMMENT=${4:-}

# if [[ -z "$RECORD_TYPE" || -z "$RECORD_TTL" || -z "$RECORD_PROXIED" || -z "$RECORD_COMMENT" ]]; then
#   log "Error: Missing required arguments."
#   usage
#   exit 1
# fi

# Get external IP for record content
NEW_RECORD_CONTENT=$(curl -s https://api.ipify.org)

for DOMAIN in "${!CLOUDFLARE_DETAILS[@]}"; do
  VALUE="${CLOUDFLARE_DETAILS[$DOMAIN]}"
  IFS=":" read -r ZONE_ID TOKEN <<<"$VALUE"
  echo -e "Updating $DOMAIN with Zone ID $ZONE_ID\n"
  if [[ -z "$ZONE_ID" || -z "$TOKEN" ]]; then
    echo "Error: Zone ID or token missing for domain '$DOMAIN'"
    exit 1
  fi
  # Get the DNS record ID
  if DNS_RECORD_ID=$(sh "$DIR_PATH"/get-id-by-domain.sh $DOMAIN $ZONE_ID $TOKEN); then
    log "Successfully retrieved DNS record ID: $DNS_RECORD_ID"
    echo 
  else
    log "Error: Failed to retrieve DNS record ID for domain: $DOMAIN"
    exit 1
  fi
done
