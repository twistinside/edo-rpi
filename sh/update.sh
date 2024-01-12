#!/bin/bash

# Load Mastodon config
source ~/.mastodon/config

# API URL (from config file)
api_url="$MASTODON_URL/api/v1/statuses"

# Access token (from config file)
access_token="$ACCESS_TOKEN"

# Log file location
log_file="$HOME/.mastodon/api.log"

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

# Prepare and post the message

# Prepare the message
if [ "$upgraded_packages" -eq 0 ]; then
    message="I just wasted ${update_duration} seconds updating my package list and ${upgrade_duration} seconds upgrading nothing at all!"
else
    message="I'm fully upgraded!%0AUpdating my package list took ${update_duration} seconds.%0AI upgraded ${upgraded_packages} packages in ${upgrade_duration} seconds.%0AI'm better than ever!"
fi

curl -X POST -H "Authorization: Bearer $access_token" -d "status=$message" $api_url >> $log_file 2>&1

# Clean up
rm /tmp/apt_upgrade.log
