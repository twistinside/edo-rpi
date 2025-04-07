#!/bin/bash
set -euo pipefail

# Load Pushover config
source ~/.pushover/config

# Pushover API endpoint and user details (from config file)
api_url="https://api.pushover.net/1/messages.json"
user_key="$USER_KEY"
app_token="$EDO_ACCESS_TOKEN"

directories=(
  "raspios_arm64" "raspios_armhf" "raspios_full_arm64" "raspios_full_armhf"
  "raspios_lite_arm64" "raspios_lite_armhf" "raspios_oldstable_arm64"
  "raspios_oldstable_armhf" "raspios_oldstable_full_arm64"
  "raspios_oldstable_full_armhf" "raspios_oldstable_lite_arm64"
  "raspios_oldstable_lite_armhf"
)

# Initialize summary variables
success_list=()
failure_list=()
skipped_list=()

# Get the initial list of active torrents (by their names)
active_torrents=$(transmission-remote -l | tail -n +2 | awk '{print $NF}')

for dir in "${directories[@]}"; do
  baseurl="https://downloads.raspberrypi.com/$dir/images/"
  
  # Get the most recent directory (assuming ordering with tail -1)
  recentdir=$(curl -s "$baseurl" | grep raspios | tail -1 | awk -F '>' '{print $7}' | sed 's/.\{3\}$//')
  fullurl="${baseurl}${recentdir}"
  
  # Get torrent filename from the full directory URL
  filename=$(curl -s "$fullurl" | grep torrent | awk -F '>' '{print $6}' | cut -d "\"" -f 2)
  base_filename="${filename%.torrent}"
  url="${fullurl}${filename}"

  # Check if the torrent is already active (compare without .torrent)
  if echo "$active_torrents" | grep -q "$base_filename"; then
    skipped_list+=("$filename")
    continue
  fi

  response=$(transmission-remote -a "$url" 2>&1)

  if [[ $response == *"success"* ]]; then
    success_list+=("$filename")
    # Append the base filename to active torrents
    active_torrents+=$'\n'"$base_filename"
  else
    failure_list+=("$filename")
  fi

  # Add the torrent using transmission-remote
  response=$(transmission-remote -a "$url" 2>&1)

  if [[ $response == *"success"* ]]; then
    success_list+=("$filename")
    # Update active_torrents so that later iterations know this torrent is already added
    active_torrents+=$'\n'"$filename"
  else
    failure_list+=("$filename")
  fi
done

# After the loop, only send a notification if there are newly added torrents
if [ ${#success_list[@]} -gt 0 ]; then
  # Create the Pushover message
  message="I found ${#success_list[@]} new torrents to add to Transmit!

  New torrent file names:
  $(printf "  - %s\n" "${success_list[@]}")"

  # Send notification to Pushover
  curl -s \
    -F "token=$app_token" \
    -F "user=$user_key" \
    -F "title=Torrent Update" \
    -F "message=$message" \
    "$api_url"
fi
