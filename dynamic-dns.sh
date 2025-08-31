#!/usr/bin/env bash
source ~/.bashrc
DIR_PATH="$(dirname "$(readlink -f "$0")")"
set -euo pipefail

# Function to log messages with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

usage() {
  cat <<EOF
Usage: $0 [RECORD_NAME] [RECORD_TYPE] [TTL] [PROXIED] [COMMENT]

Update a DNS record on Cloudflare via API.

Arguments:
  RECORD_NAME      DNS record name (e.g., sub.example.com)
  RECORD_TYPE      DNS record type (e.g., A, CNAME, TXT)
  TTL              TTL in seconds (1 = automatic)
  PROXIED          true or false - proxied through Cloudflare
  COMMENT          Optional comment

Note:
  RECORD_CONTENT will be automatically set to your external IP.

Environment variables:
  CLOUDFLARE_ZONE_ID and CLOUDFLARE_TOKEN must be set.

Example:
  $0 sub.example.com A 300 true "Auto-created record"
EOF
}

# Show usage and exit if help is requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Read arguments
RECORD_NAME=${1:-}
RECORD_TYPE=${2:-}
RECORD_TTL=${3:-}
RECORD_PROXIED=${4:-}
RECORD_COMMENT=${5:-}

# Get external IP for record content
NEW_RECORD_CONTENT=$(curl -s https://api.ipify.org)

# Validate arguments
if [[ -z "$RECORD_NAME" || -z "$RECORD_TYPE" || -z "$RECORD_TTL" || -z "$RECORD_PROXIED" || -z "$RECORD_COMMENT" ]]; then
  log "Error: Missing required arguments."
  usage
  exit 1
fi

# Check required environment variables
if [[ -z "${CLOUDFLARE_ZONE_ID:-}" || -z "${CLOUDFLARE_TOKEN:-}" ]]; then
  log "Error: CLOUDFLARE_ZONE_ID and CLOUDFLARE_TOKEN must be set." >&2
  exit 1
fi

# Get the DNS record ID
if DNS_RECORD_ID=$(sh "$DIR_PATH"/get-id-by-domain.sh "$RECORD_NAME"); then
  log "Successfully retrieved DNS record ID: $DNS_RECORD_ID"
else
  log "Error: Failed to retrieve DNS record ID for domain: $RECORD_NAME"
  exit 1
fi

# Get the DNS record content
if DNS_RECORD_CONTENT=$(sh "$DIR_PATH"/get-record-content-by-domain.sh "$RECORD_NAME"); then
  log "Successfully retrieved DNS record ID: $DNS_RECORD_CONTENT"
else
  log "Error: Failed to retrieve DNS record ID for domain: $RECORD_NAME"
  exit 1
fi

log "Current IP: $NEW_RECORD_CONTENT"
log "Existing DNS Record ID: $DNS_RECORD_CONTENT"
echo "test"
# Check if update is needed
if [ "$NEW_RECORD_CONTENT" == "$DNS_RECORD_CONTENT" ]; then
  log "IP address is still the same, no need to update"
  exit 0
fi

# Update the DNS record
response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$DNS_RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
        \"type\": \"$RECORD_TYPE\",
        \"name\": \"$RECORD_NAME\",
        \"content\": \"$NEW_RECORD_CONTENT\",
        \"ttl\": $RECORD_TTL,
        \"proxied\": $RECORD_PROXIED,
        \"comment\": \"$RECORD_COMMENT\"
      }")

# Extract 'success' field
success=$(echo "$response" | jq -r '.success')

# Check result
if [ "$success" == "true" ]; then
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
