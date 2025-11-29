#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config

log_info "Starting package list update."
start_time=$(date +%s)
sudo apt-get update
end_time=$(date +%s)
update_duration=$((end_time - start_time))
log_info "apt-get update completed in ${update_duration}s."

log_info "Starting package upgrade."
start_time=$(date +%s)
sudo apt-get upgrade -y | tee /tmp/apt_upgrade.log
end_time=$(date +%s)
upgrade_duration=$((end_time - start_time))
log_info "apt-get upgrade completed in ${upgrade_duration}s."

upgraded_packages=$(grep -cP 'Setting up \K[^ ]+' /tmp/apt_upgrade.log || true)

if [ "$upgraded_packages" -eq 0 ]; then
    message="I just spent ${update_duration} seconds updating my package list and ${upgrade_duration} seconds upgrading nothing at all!"
else
    message="I'm fully upgraded! Updating my package list took ${update_duration} seconds. I upgraded ${upgraded_packages} packages in ${upgrade_duration} seconds. I'm better than ever!"
fi

send_pushover "$message" "System Update"
log_info "System update notification sent."

rm /tmp/apt_upgrade.log
log_info "Temporary files cleaned up."
