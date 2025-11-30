#!/bin/bash
# Pilot: Edo Pi log monitor using OpenAI analysis and Pushover notifications.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config
load_openai_config

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
    if [[ -r /var/log/auth.log ]]; then
      local failed_attempts
      failed_attempts=$(grep -i "Failed password" /var/log/auth.log | tail -n 20 | tr -cd '\11\12\15\40-\176' || true)
      health+=("Recent failed SSH attempts (last 20):")
      health+=("${failed_attempts:-none found}")
    else
      health+=("Recent failed SSH attempts: auth.log not readable (permission denied)")
    fi
  else
    health+=("Recent failed SSH attempts: auth.log not found")
  fi

  if command -v systemctl >/dev/null 2>&1; then
    health+=("systemctl --failed:")
    health+=("$(systemctl --failed --no-pager 2>/dev/null | tr -cd '\11\12\15\40-\176')")
  else
    health+=("systemctl status: unavailable")
  fi

  printf '%s\n' "${health[@]}"
}

collect_logs() {
  local collected=()

  for file in $LOG_FILES; do
    if [[ -f "$file" ]]; then
      if [[ -r "$file" ]]; then
        collected+=("=== $file (last ${TAIL_LINES} lines) ===")
        collected+=("$(tail -n "$TAIL_LINES" "$file" | tr -cd '\11\12\15\40-\176' || true)")
      else
        collected+=("=== $file not readable (permission denied) ===")
      fi
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
    '{model: $model, input: [{role: "system", content: $system}, {role: "user", content: $user}], max_output_tokens: 350, response_format: {type: "text"}}')

  local response
  if ! response=$(curl -sS "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -d "$payload"); then
    return 1
  fi

  local message
  message=$(echo "$response" | jq -r '.output[0].content[0].text // empty')

  if [[ -z "$message" ]]; then
    message=$(echo "$response" | jq -r '.choices[0].message.content // empty')
  fi

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
