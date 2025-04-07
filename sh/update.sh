#!/bin/bash

# Load Pushover config
source ~/.pushover/config

# API URL for Pushover
api_url="https://api.pushover.net/1/messages.json"

# Application key and user key (from config file)
app_token="$EDO_ACCESS_TOKEN"
user_key="$USER_KEY"

# Run apt-get update and measure time
start_time=$(date +%s)
sudo apt-get update
end_time=$(date +%s)
update_duration=$((end_time - start_time))

# Run apt-get upgrade, count packages, and measure time
start_time=$(date +%s)
sudo apt-get upgrade -y | tee /tmp/apt_upgrade.log
end_time=$(date +%s)
upgrade_duration=$((end_time - start_time))

# Count upgraded packages
upgraded_packages=$(grep -oP 'Setting up \K[^ ]+' /tmp/apt_upgrade.log | wc -l)

# Prepare the message
if [ "$upgraded_packages" -eq 0 ]; then
    message="I just spent ${update_duration} seconds updating my package list and ${upgrade_duration} seconds upgrading nothing at all!"
else
    message="I'm fully upgraded! Updating my package list took ${update_duration} seconds. I upgraded ${upgraded_packages} packages in ${upgrade_duration} seconds. I'm better than ever!"
fi

# Post to Pushover using curl and log the output
curl -s -X POST \
    --form-string "token=$app_token" \
    --form-string "user=$user_key" \
    --form-string "message=$message" \
    $api_url

# Clean up
rm /tmp/apt_upgrade.log
