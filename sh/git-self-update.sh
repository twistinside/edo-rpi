#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=${REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}
SYSTEMD_DIR="$REPO_DIR/systemd"

source "$SCRIPT_DIR/common.sh"
trap_errors

log_info "Starting git self-update for $REPO_DIR."

if [[ ! -d "$REPO_DIR" ]]; then
  log_error "Repository directory $REPO_DIR does not exist."
  exit 1
fi

cd "$REPO_DIR"
previous_ref=$(git rev-parse HEAD)

log_info "Running git pull in $REPO_DIR."
git pull

current_ref=$(git rev-parse HEAD)

if [[ "$previous_ref" == "$current_ref" ]]; then
  log_info "Repository already up to date."
  exit 0
fi

log_info "Repository updated from $previous_ref to $current_ref. Checking for systemd unit changes."
if git diff --name-only "$previous_ref" "$current_ref" | grep -q '^systemd/'; then
  log_info "Systemd units changed; reinstalling."
  "$SCRIPT_DIR/bootstrap-install.sh"
else
  log_info "No systemd changes detected."
fi

log_info "Git self-update complete."
