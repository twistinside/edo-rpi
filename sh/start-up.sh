#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors

log_info "Running startup hook (add custom tasks to sh/start-up.sh)."

# Add any one-time boot actions below. The placeholder ensures the systemd unit
# succeeds even if no commands are specified yet.

exit 0
