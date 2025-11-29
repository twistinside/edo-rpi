#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config

if [[ -x "$HOME/sh/uptime.sh" ]]; then
    uptime=$($HOME/sh/uptime.sh)
else
    uptime=$(uptime -p | sed 's/^up //')
fi

message="I've been up for $uptime, so I'm going to take a quick rest... See you soon!"

send_pushover "$message" "Reboot" "Reboot"
log_info "Reboot notification sent."

sudo reboot
