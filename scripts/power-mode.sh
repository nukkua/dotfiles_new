#!/usr/bin/env bash
set -euo pipefail

# Toggle/apply laptop power mode via power-profiles-daemon.
# Usage:
#   power-mode.sh toggle        # performance <-> power-saver
#   power-mode.sh performance
#   power-mode.sh battery       # alias: power-saver
#   power-mode.sh balanced
#   power-mode.sh status

notify() {
  local title="$1" body="${2:-}"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" >/dev/null 2>&1 || true
  fi
  printf '%s%s\n' "$title" "${body:+ - $body}"
}

need_powerprofiles() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    notify "Power mode error" "powerprofilesctl missing: sudo pacman -S power-profiles-daemon"
    exit 1
  fi

  if ! systemctl is-active --quiet power-profiles-daemon.service; then
    notify "Power mode error" "power-profiles-daemon not active: sudo systemctl enable --now power-profiles-daemon"
    exit 1
  fi
}

current_profile() {
  powerprofilesctl get 2>/dev/null || echo "unknown"
}

set_profile() {
  local profile="$1"
  powerprofilesctl set "$profile"

  case "$profile" in
    performance)
      notify "Performance mode" "Max speed. More heat + battery drain."
      ;;
    power-saver)
      notify "Battery saver" "Lower power. Cooler + longer battery."
      ;;
    balanced)
      notify "Balanced mode" "Middle ground."
      ;;
  esac
}

need_powerprofiles

case "${1:-toggle}" in
  performance|perf)
    set_profile performance
    ;;
  battery|save|saver|power-saver)
    set_profile power-saver
    ;;
  balanced|balance)
    set_profile balanced
    ;;
  status)
    notify "Power mode" "$(current_profile)"
    ;;
  toggle)
    case "$(current_profile)" in
      performance) set_profile power-saver ;;
      *) set_profile performance ;;
    esac
    ;;
  *)
    echo "Usage: $0 [toggle|performance|battery|balanced|status]" >&2
    exit 2
    ;;
esac
