#!/bin/bash

# Load Mastodon config
source ~/.mastodon/config

# API URL (from config file)
api_url="$MASTODON_URL/api/v1/statuses"

# Access token (from config file)
access_token="$ACCESS_TOKEN"

# Get the current time as the reboot time in seconds since epoch
reboot_sec=$(date '+%s')

# Get the last shutdown time
last_shutdown=$(last -x | grep shutdown | head -1 | awk '{ print $5 " " $6 " " $7 " " $8 }')

# Convert times to seconds since epoch
shutdown_sec=$(date -d "$last_shutdown" '+%s')

# Calculate downtime in seconds
downtime=$((reboot_sec - shutdown_sec))

# Message to post
message="I just woke up from a reboot.%0AI was asleep for $downtime seconds... What did I miss?"

# Log file location within the private Mastodon folder
log_file="$HOME/.mastodon/api.log"

# Post to Mastodon using curl and log the output
curl -X POST -H "Authorization: Bearer $access_token" -d "status=$message" $api_url >> $log_file 2>&1

# Add timestamp to the log
echo " - Posted on: $(date)" >> $log_file
