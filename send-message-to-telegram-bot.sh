if [ -z "$1" ]; then
  echo "Error: Missing required arguments"
  exit 1;
fi

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "Error: TELEGRAM_TOKEN and TELEGRAM_CHAT_ID environment variables must be set."
  exit 1
fi

curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage \
     -d chat_id=${TELEGRAM_CHAT_ID} \
     -d text="$1"
