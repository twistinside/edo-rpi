#!/bin/bash
# Common helpers for Edo Pi shell scripts.

set -euo pipefail

PUSHOVER_API_URL=${PUSHOVER_API_URL:-"https://api.pushover.net/1/messages.json"}
CONFIG_FILE=${CONFIG_FILE:-"$HOME/.pushover/config"}
LOG_FILE=${LOG_FILE:-"$HOME/.pushover/api.log"}
OPENAI_CONFIG=${OPENAI_CONFIG:-"$HOME/.openai/config"}

ensure_log_file() {
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"
}

log_info() {
  local message=$1
  ensure_log_file
  printf '%s [INFO] %s\n' "$(date --iso-8601=seconds)" "$message" | tee -a "$LOG_FILE" >&2
}

log_error() {
  local message=$1
  ensure_log_file
  printf '%s [ERROR] %s\n' "$(date --iso-8601=seconds)" "$message" | tee -a "$LOG_FILE" >&2
}

trap_errors() {
  trap 'log_error "Script ${0##*/} failed at line ${LINENO}."' ERR
}

load_pushover_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Pushover config not found at $CONFIG_FILE"
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$CONFIG_FILE"

  if [[ -z "${EDO_ACCESS_TOKEN:-}" || -z "${USER_KEY:-}" ]]; then
    log_error "EDO_ACCESS_TOKEN or USER_KEY is missing from the config."
    exit 1
  fi
}

send_pushover() {
  local message=$1
  local title=${2:-"Edo Pi Notification"}
  local subject=${3:-""}

  local -a curl_args=(
    -sS -X POST "$PUSHOVER_API_URL"
    --form-string "token=$EDO_ACCESS_TOKEN"
    --form-string "user=$USER_KEY"
    --form-string "message=$message"
  )

  [[ -n "$title" ]] && curl_args+=(--form-string "title=$title")
  [[ -n "$subject" ]] && curl_args+=(--form-string "subject=$subject")

  local response
  if ! response=$(curl "${curl_args[@]}" 2>&1); then
    log_error "Failed to send Pushover message: $response"
    return 1
  fi

  log_info "Pushover message sent (${title:-no title})."
  echo "$response" >> "$LOG_FILE"
}

load_openai_config() {
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    return
  fi

  if [[ -f "$OPENAI_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$OPENAI_CONFIG"
  else
    log_error "OpenAI config not found at $OPENAI_CONFIG and OPENAI_API_KEY is not set."
    exit 1
  fi

  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    log_error "OPENAI_API_KEY is missing from $OPENAI_CONFIG."
    exit 1
  fi
}
