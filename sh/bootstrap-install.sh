#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=${REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}
SYSTEMD_SRC="$REPO_DIR/systemd"

source "$SCRIPT_DIR/common.sh"
trap_errors

log_info "Installing systemd units from $SYSTEMD_SRC."

if [[ ! -d "$SYSTEMD_SRC" ]]; then
  log_error "Systemd directory not found at $SYSTEMD_SRC."
  exit 1
fi

mapfile -t unit_files < <(find "$SYSTEMD_SRC" -maxdepth 1 -type f \( -name '*.service' -o -name '*.timer' \))

if [[ ${#unit_files[@]} -eq 0 ]]; then
  log_error "No systemd unit files found in $SYSTEMD_SRC."
  exit 1
fi

for unit in "${unit_files[@]}"; do
  unit_name=$(basename "$unit")
  log_info "Installing $unit_name to /etc/systemd/system/."
  sudo install -m 644 "$unit" "/etc/systemd/system/$unit_name"
done

log_info "Reloading systemd units."
sudo systemctl daemon-reload

for timer in "${unit_files[@]}"; do
  if [[ "$timer" == *.timer ]]; then
    timer_name=$(basename "$timer")
    log_info "Enabling and starting $timer_name."
    sudo systemctl enable --now "$timer_name"
  fi
done

log_info "Systemd unit installation complete."
