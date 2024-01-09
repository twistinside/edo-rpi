#!/bin/bash

# Load Mastodon config
source ~/.mastodon/config

# API URL (from config file)
api_url="$MASTODON_URL/api/v1/statuses"

# Access token (from config file)
access_token="$ACCESS_TOKEN"

# Message to post
message="I just woke up from a reboot."

# Log file location within the private Mastodon folder
log_file="$HOME/.mastodon/api.log"

# Post to Mastodon using curl and log the output
curl -X POST -H "Authorization: Bearer $access_token" -d "status=$message" $api_url >> $log_file 2>&1

# Add timestamp to the log
echo " - Posted on: $(date)" >> $log_file
