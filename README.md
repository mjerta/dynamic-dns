# Dynamic DNS Update Scripts

This repository contains a set of Bash scripts for managing Dynamic DNS records, primarily with Cloudflare and Telegram integration. These scripts allow you to automate DNS updates, retrieve DNS record information, and send notifications via Telegram.

## Scripts Overview

- `dynamic-dns.sh`: Main script to update DNS records dynamically.
- `get-id-by-domain.sh`: Retrieves the Cloudflare record ID for a given domain.
- `get-record-content-by-domain.sh`: Gets the current DNS record content for a domain.
- `list-dns-records.sh`: Lists all DNS records for your Cloudflare account.
- `send-message-to-telegram-bot.sh`: Sends a message to a Telegram chat using a bot.

## Configuration

The scripts use a configuration file named `dynamic-dns.conf` to store domain and API token information.

> **Notice:**
> The `dynamic-dns.conf` file in this repository is a template/example. You should replace the domain names, tokens, and IDs with your own values. Do not use the example file as-is for production or personal use. Always keep your sensitive information secure and do not commit real tokens or secrets to version control.

### Setup Instructions

1. **Copy the example config file:**
   - Copy `dynamic-dns-example.sh` to `dynamic-dns.conf` (or your preferred config name).
   - Edit `dynamic-dns.conf` with your own domains and tokens.
2. **Delete the example file:**
   - After copying and editing, you may delete `dynamic-dns-example.sh` to avoid confusion.
3. **Security:**
   - The `.gitignore` in this directory ensures that `dynamic-dns.conf` is never tracked by git. This keeps your secrets safe.
   - Only the example/template file should ever be tracked in version control.

Example structure of `dynamic-dns.conf`:

```bash
source ~/.bashrc

declare -A CLOUDFLARE_DETAILS
CLOUDFLARE_DETAILS["yourdomain.example.com"]="${CLOUDFLARE_ZONE_ID}:${CLOUDFLARE_TOKEN}"

TELEGRAM_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
```

- Replace `yourdomain.example.com` and the environment variable names with your actual domain and credentials.
- Store your secrets in environment variables or a secure secrets manager.

## Usage

1. Copy and edit `dynamic-dns.conf` with your own domains and tokens.
2. Source the config file in your shell or ensure the scripts can access the required environment variables.
3. Run the desired script, e.g.:
   ```bash
   ./dynamic-dns.sh
   ```

## Security
- **Never commit real API tokens, secrets, or sensitive data to this repository.**
- Use environment variables or a secure secrets manager to handle credentials.

## Running with Cron

To automatically update your DNS every 15 minutes, add the following line to your crontab (edit with `crontab -e`):

```
*/15 * * * * /path/to/dynamic-dns.sh >> /var/log/dynamic-dns.log 2>&1
```

- Replace `/path/to/dynamic-dns.sh` with the full path to your script.
- The output will be logged to `/var/log/dynamic-dns.log`.
