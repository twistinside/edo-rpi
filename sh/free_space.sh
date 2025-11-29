#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config

log_info "Checking filesystem utilization."
mapfile -t disk_rows < <(df -h --output=target,pcent,avail -x tmpfs -x devtmpfs | awk 'NR>1')

message_lines=("Storage check complete:")
for row in "${disk_rows[@]}"; do
    read -r mount_point percent_used space_available <<< "$row"
    percent_used_no_pct="${percent_used%%%}"  # strip trailing %
    message_lines+=("${mount_point}: ${space_available} free (${percent_used_no_pct}% used)")
done

message=$(printf "%s\n" "${message_lines[@]}")

send_pushover "$message" "Disk Status Update"
log_info "Disk status notification sent."
