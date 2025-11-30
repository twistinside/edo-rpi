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

if ! compgen -G "$SYSTEMD_SRC/*.service" > /dev/null; then
  log_error "No systemd service files found in $SYSTEMD_SRC."
  exit 1
fi

if ! compgen -G "$SYSTEMD_SRC/*.timer" > /dev/null; then
  log_error "No systemd timer files found in $SYSTEMD_SRC."
  exit 1
fi

pushd "$SYSTEMD_SRC" > /dev/null

log_info "Copying service units into /etc/systemd/system/."
sudo cp *.service /etc/systemd/system/

log_info "Copying timer units into /etc/systemd/system/."
sudo cp *.timer /etc/systemd/system/

log_info "Reloading systemd units."
sudo systemctl daemon-reload

log_info "Enabling and starting timers."
sudo systemctl enable --now *.timer

popd > /dev/null

log_info "Systemd unit installation complete."
