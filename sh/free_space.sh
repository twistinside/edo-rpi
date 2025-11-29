#!/bin/bash

set -euo pipefail

# Load Pushover config
source "$HOME/.pushover/config"

# API URL for Pushover
pushover_api_url="https://api.pushover.net/1/messages.json"

# Application key and user key
app_token="$EDO_ACCESS_TOKEN"
user_key="$USER_KEY"

# Build a summary for all non-ephemeral filesystems
mapfile -t disk_rows < <(df -h --output=target,pcent,avail -x tmpfs -x devtmpfs | awk 'NR>1')

message_lines=("Storage check complete:")
for row in "${disk_rows[@]}"; do
    read -r mount_point percent_used space_available <<< "$row"
    percent_used_no_pct="${percent_used%%%}"  # strip trailing %
    message_lines+=("${mount_point}: ${space_available} free (${percent_used_no_pct}% used)")
done

message=$(printf "%s\n" "${message_lines[@]}")

# Send to Pushover
curl -s -X POST "$pushover_api_url" \
    --form-string "token=$app_token" \
    --form-string "user=$user_key" \
    --form-string "message=$message" \
    --form-string "title=Disk Status Update" \
    >> "$HOME/.pushover/api.log"

# Log the timestamp
echo " - Pushover alert sent on: $(date)" >> "$HOME/.pushover/api.log"
