#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors

log_info "Running startup hook (add custom tasks to sh/start-up.sh)."

disable_gldriver_test() {
  local service="gldriver-test.service"
  local timer="gldriver-test.timer"

  log_info "Checking for legacy GL driver test units."

  if systemctl list-unit-files "$service" >/dev/null 2>&1; then
    if systemctl is-enabled "$service" >/dev/null 2>&1; then
      log_info "Disabling $service because it fails on headless setups."
      sudo systemctl disable --now "$service"
    else
      log_info "$service already disabled or static."
    fi
  else
    log_info "$service not installed; nothing to do."
  fi

  if systemctl list-unit-files "$timer" >/dev/null 2>&1; then
    if systemctl is-enabled "$timer" >/dev/null 2>&1; then
      log_info "Disabling $timer to stop recurring failures."
      sudo systemctl disable --now "$timer"
    else
      log_info "$timer already disabled or static."
    fi
  else
    log_info "$timer not installed; nothing to do."
  fi
}

disable_gldriver_test

log_info "Startup hook complete."
