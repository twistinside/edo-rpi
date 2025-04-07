#!/bin/bash

# Load Pushover config
source "$HOME/.pushover/config"

# API URL for Pushover
pushover_api_url="https://api.pushover.net/1/messages.json"

# Application key and user key
app_token="$EDO_ACCESS_TOKEN"
user_key="$USER_KEY"

# Function to get disk stats
get_disk_stats() {
    local mount_point="$1"
    df -h "$mount_point" | awk 'NR==2 { gsub("%", "", $5); print $5, $4 }'
}

# Get stats for root and SSD
read sd_percent_used sd_free_space <<< "$(get_disk_stats "/")"
read ssd_percent_used ssd_free_space <<< "$(get_disk_stats "/mnt/ssd")"

# Compose message
# Use real newlines for formatting
message="Storage check complete.
SD card: ${sd_percent_used}% full, ${sd_free_space} free.
HDD: ${ssd_percent_used}% full, ${ssd_free_space} free."

# Send to Pushover
curl -s -X POST "$pushover_api_url" \
    --form-string "token=$app_token" \
    --form-string "user=$user_key" \
    --form-string "message=$message" \
    --form-string "title=Disk Status Update" \
    >> "$HOME/.pushover/api.log"

# Log the timestamp
echo " - Pushover alert sent on: $(date)" >> "$HOME/.pushover/api.log"

