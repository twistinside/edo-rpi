#!/bin/bash

# Read Mastodon configuration from the config file
source ~/.mastodon/config

# API URL (from config file)
api_url="${MASTODON_URL}/api/v1/statuses"

# Access token (from config file)
access_token="${ACCESS_TOKEN}"

# Function to get disk usage stats
get_disk_stats() {
    local mount_point="$1"
    local usage_stats=$(df -h "$mount_point" | awk 'NR==2{print $5 " " $4}')
    
    echo "$usage_stats"
}

# Get stats for both drives
sd_stats=$(get_disk_stats "/")
ssd_stats=$(get_disk_stats "/mnt/ssd")

sd_percent_used=$(echo "${sd_stats%% *}" | tr -d '%')
ssd_percent_used=$(echo "${ssd_stats%% *}" | tr -d '%')

sd_free_space=${sd_stats##* }
ssd_free_space=${ssd_stats##* }

# Format the message
message="I checked the status of my storage.%0AMy micro SD card is ${sd_percent_used}%25 full, and my external SSD is ${ssd_percent_used}%25 full.%0AThat leaves my disks with ${sd_free_space} and ${ssd_free_space} free."

# Log file location within the private Mastodon folder
log_file="$HOME/.mastodon/api.log"

# Post to Mastodon and log
curl -X POST -H "Authorization: Bearer $access_token" -d "status=$message" "$api_url" >> "$log_file" 2>&1

# Add timestamp to the log
echo " - Posted on: $(date)" >> "$log_file"
