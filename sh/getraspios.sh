#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

trap_errors
load_pushover_config

directories=(
  "raspios_arm64" "raspios_armhf" "raspios_full_arm64" "raspios_full_armhf"
  "raspios_lite_arm64" "raspios_lite_armhf" "raspios_oldstable_arm64"
  "raspios_oldstable_armhf" "raspios_oldstable_full_arm64"
  "raspios_oldstable_full_armhf" "raspios_oldstable_lite_arm64"
  "raspios_oldstable_lite_armhf"
)

log_info "Querying Transmission for active torrents."
if ! mapfile -t active_torrents < <(
  transmission-remote -l \
    | tail -n +2 \
    | sed '/^[[:space:]]*Sum:/d' \
    | sed 's/^ *//' \
    | sed 's/  */ /g' \
    | cut -d' ' -f9-
); then
  log_error "Unable to query Transmission for active torrents."
  exit 1
fi

declare -A active_map=()
for torrent in "${active_torrents[@]}"; do
  [[ -n "$torrent" ]] && active_map["$torrent"]=1
done

success_list=()
failure_list=()

for dir in "${directories[@]}"; do
  baseurl="https://downloads.raspberrypi.com/$dir/images/"

  if ! index_html=$(curl -fsSL "$baseurl"); then
    failure_list+=("$dir (unable to read index)")
    continue
  fi

  recentdir=$({
    printf '%s\n' "$index_html" \
      | grep -oE 'href="[^\"]+/"' \
      | cut -d '"' -f2 \
      | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-' \
      | sort \
      | tail -n 1;
  } || true)

  if [[ -z "$recentdir" ]]; then
    failure_list+=("$dir (no releases found)")
    continue
  fi

  fullurl="${baseurl}${recentdir}"

  if ! release_html=$(curl -fsSL "$fullurl"); then
    failure_list+=("$dir (unable to read release page)")
    continue
  fi

  filename=$({
    printf '%s\n' "$release_html" \
      | grep -oE 'href="[^"]+\.torrent"' \
      | head -n 1 \
      | cut -d '"' -f2;
  } || true)

  if [[ -z "$filename" ]]; then
    failure_list+=("$dir (no torrent found)")
    continue
  fi

  base_filename="${filename%.torrent}"

  if [[ -n "${active_map[$base_filename]:-}" ]]; then
    continue
  fi

  response=$(transmission-remote -a "${fullurl}${filename}" 2>&1)
  if [[ "$response" == *"success"* ]]; then
    success_list+=("$base_filename")
    active_map["$base_filename"]=1
  else
    failure_list+=("$base_filename (Transmission error)")
  fi

done

if (( ${#success_list[@]} )); then
  printf -v message "Found %d new Raspberry Pi image torrent(s):\n" "${#success_list[@]}"
  for name in "${success_list[@]}"; do
    message+=$'- '
    message+="$name"
    message+=$'\n'
  done
  message+=$'\nThey have been added to Transmission.'

  send_pushover "$message" "New Raspberry Pi Images"
  log_info "Torrent notification sent for ${#success_list[@]} images."
fi

if (( ${#failure_list[@]} )); then
  printf 'Failed to process: %s\n' "${failure_list[*]}" >&2
  log_error "Failed to process: ${failure_list[*]}"
fi

exit 0
