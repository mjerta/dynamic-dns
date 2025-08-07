if [ -z "$1" ]; then
  echo "Error: Missing required arguments"
  exit 1;
fi


curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage \
     -d chat_id=${TELEGRAM_CHAT_ID} \
     -d text="$1"
