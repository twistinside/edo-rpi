#!/bin/bash

# Load Pushover config
source ~/.pushover/config

# API URL for Pushover
api_url="https://api.pushover.net/1/messages.json"

# Application key and user key (from config file)
app_token="$EDO_ACCESS_TOKEN"
user_key="$USER_KEY"

# Get uptime and convert it to hours and minutes
uptime=$($HOME/sh/uptime.sh)

# Message to send
message="I've been up for $uptime, so I'm going to take a quick rest... See you soon!"

# Post to Pushover using curl and log the output
curl -s -X POST \
    --form-string "token=$app_token" \
    --form-string "user=$user_key" \
    --form-string "message=$message" \
    --form-string "subject=Reboot" \
    $api_url

# Reboot the system
sudo reboot
