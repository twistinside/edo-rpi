#!/bin/bash
# Pilot: Edo Pi log monitor using OpenAI analysis and Pushover notifications.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config

: "${OPENAI_API_KEY:?Environment variable OPENAI_API_KEY is required.}"

if ! command -v jq >/dev/null 2>&1; then
  log_error "jq is required to run Pilot."
  exit 1
fi

LOG_FILES=${LOG_FILES:-"/var/log/syslog /var/log/auth.log"}
TAIL_LINES=${TAIL_LINES:-400}
OPENAI_MODEL=${OPENAI_MODEL:-"gpt-5.1-codex-mini"}
PILOT_TITLE=${PILOT_TITLE:-"Pilot Log Review"}

collect_health() {
  local health=()

  health+=("=== Health snapshot ===")

  if command -v uptime >/dev/null 2>&1; then
    health+=("Uptime: $(uptime -p 2>/dev/null || uptime)")
    health+=("Load averages: $(uptime | sed 's/.*load average[s]*: //')")
  else
    health+=("Uptime/load: unavailable")
  fi

  health+=("Disk usage (root):")
  health+=("$(df -h / | tr -cd '\11\12\15\40-\176')")

  if [[ -f /var/log/auth.log ]]; then
    health+=("Recent failed SSH attempts (last 20):")
    health+=("$( { grep -i "Failed password" /var/log/auth.log || true; } | tail -n 20 | tr -cd '\11\12\15\40-\176')")
  else
    health+=("Recent failed SSH attempts: auth.log not found")
  fi

  if command -v systemctl >/dev/null 2>&1; then
    health+=("systemctl --failed:")
    health+=("$( { systemctl --failed --no-pager 2>/dev/null || true; } | tr -cd '\11\12\15\40-\176')")
  else
    health+=("systemctl status: unavailable")
  fi

  printf '%s\n' "${health[@]}"
}

collect_logs() {
  local collected=()

  for file in $LOG_FILES; do
    if [[ -f "$file" ]]; then
      collected+=("=== $file (last ${TAIL_LINES} lines) ===")
      collected+=("$(tail -n "$TAIL_LINES" "$file" | tr -cd '\11\12\15\40-\176')")
    else
      collected+=("=== $file not found ===")
    fi
  done

  printf '%s\n' "${collected[@]}"
}

build_prompt() {
  cat <<'PROMPT'
You are Pilot, a maintenance assistant for a Raspberry Pi home server. Review the provided logs and return:
1) A concise summary of recent activity.
2) Specific errors, warnings, or suspicious behavior to investigate (if any).
3) Actionable suggestions for follow-up on Edo Pi.
Health snapshots (uptime, load, disk, failed SSH attempts, systemctl --failed) may be included alongside logs; consider them when flagging issues.
Keep the response short and numbered. If everything looks healthy, say so.
PROMPT
}

call_openai() {
  local content=$1
  local prompt
  prompt=$(build_prompt)

  local payload
  payload=$(jq -n --arg model "$OPENAI_MODEL" --arg system "$prompt" --arg user "$content" \
    '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}], max_tokens: 350}')

  local response
  if ! response=$(curl -sS "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -d "$payload"); then
    return 1
  fi

  local message
  message=$(echo "$response" | jq -r '.choices[0].message.content // empty')

  if [[ -z "$message" ]]; then
    log_error "OpenAI returned an empty response."
    log_error "$response"
    return 1
  fi

  printf '%s\n' "$message"
}

main() {
  log_info "Collecting health snapshot and recent logs for Pilot analysis."
  local logs health
  health=$(collect_health)
  logs=$(collect_logs)

  local review_body="$health"$'\n\n'"$logs"

  if [[ -z "$logs" && -z "$health" ]]; then
    log_error "No data collected; aborting Pilot run."
    exit 1
  fi

  log_info "Sending logs to OpenAI model $OPENAI_MODEL."
  local analysis
  if ! analysis=$(call_openai "$review_body"); then
    log_error "OpenAI request failed."
    exit 1
  fi

  log_info "Dispatching Pilot summary via Pushover."
  send_pushover "$analysis" "$PILOT_TITLE"
  log_info "Pilot run complete."
}

main "$@"
