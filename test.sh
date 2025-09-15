#!/usr/bin/env bash

DIR_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$DIR_PATH/dynamic-dns.conf"

# Function to log messages with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

usage() {
  cat <<EOF
Usage: $0 [RECORD_TYPE] [TTL] [PROXIED] [COMMENT]

Update a DNS record on Cloudflare via API.

Arguments:
  RECORD_TYPE      DNS record type (e.g., A, CNAME, TXT)
  TTL              TTL in seconds (1 = automatic)
  PROXIED          true or false - proxied through Cloudflare
  COMMENT          Optional comment

Note:
  RECORD_CONTENT will be automatically set to your external IP.

Example:
  $0 sub.example.com A 300 true "Auto-created record"
EOF
}

# Show usage and exit if help is requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

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

if [[ -z "$RECORD_TYPE" || -z "$RECORD_TTL" || -z "$RECORD_PROXIED" || -z "$RECORD_COMMENT" ]]; then
  log "Error: Missing required arguments."
  usage
  exit 1
fi

# Get external IP for record content
NEW_RECORD_CONTENT=$(curl -s https://api.ipify.org)

for DOMAIN in "${!CLOUDFLARE_DETAILS[@]}"; do
  VALUE="${CLOUDFLARE_DETAILS[$DOMAIN]}"
  IFS=":" read -r ZONE_ID TOKEN <<<"$VALUE"
  echo
  log "Updating $DOMAIN with Zone ID $ZONE_ID\n"
  if [[ -z "$ZONE_ID" || -z "$TOKEN" ]]; then
    log "Error: Zone ID or token missing for domain '$DOMAIN'"
    exit 1
  fi
  # Get the DNS record ID
  if DNS_RECORD_ID=$(sh "$DIR_PATH"/get-id-by-domain.sh $DOMAIN $ZONE_ID $TOKEN); then
    log "Successfully retrieved DNS record ID: $DNS_RECORD_ID"

    DNS_RECORD_CONTENT=$(sh "$DIR_PATH"/get-record-content-by-domain.sh $DOMAIN $ZONE_ID $TOKEN)
    if [[ $? -ne 0 || -z "$DNS_RECORD_CONTENT" ]]; then
      log "Error: Failed to retrieve DNS record content for domain: $DOMAIN"
      continue # skip to next domain instead of exiting
    else
      log "Successfully retrieved DNS record content: $DNS_RECORD_CONTENT"
    fi

    log "Current IP: $NEW_RECORD_CONTENT"
    log "Existing DNS Record ID: $DNS_RECORD_CONTENT"
    # Check if update is needed
    log $NEW_RECORD_CONTENT
    if [ "$NEW_RECORD_CONTENT" == "$DNS_RECORD_CONTENT" ]; then
      log "IP address is still the same, no need to update"
      continue
    fi
    # Update the DNS record
    response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
      -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"$RECORD_TYPE\",
        \"name\": \"$RECORD_NAME\",
        \"content\": \"$NEW_RECORD_CONTENT\"
        \"ttl\": $RECORD_TTL,
        \"proxied\": $RECORD_PROXIED,
        \"comment\": \"$RECORD_COMMENT\"
      }")

    # Extract 'success' field
    success=$(echo "$response" | jq -r '.success')
    # If Telegram is setup correctly send the succes/error message

    if [[ -z "$TELEGRAM_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
      echo "Telegram token or telegram chat id missing in the conf"
      continue
    fi

    # Check result
    if [ "$success" == "true" ]; then
      echo
      message="✅ DNS record updated successfully."
      log "$message"
      sh "$DIR_PATH/send-message-to-telegram-bot.sh" "$message"
    else
      message="❌ Failed to update DNS record."
      log "$message"
      log "🔎 Error response:"
      echo "$response" | jq
      sh "$DIR_PATH/send-message-to-telegram-bot.sh" "$message"
    fi

  else
    log "Error: Failed to retrieve DNS record ID for domain: $DOMAIN"
    exit 1
  fi
done
