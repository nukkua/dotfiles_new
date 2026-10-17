#!/usr/bin/env bash
set -euo pipefail

# Disable/enable laptop built-in keyboard on Wayland.
# Detected physical keyboard: "AT Translated Set 2 keyboard" at event3 / i8042 serio0.
# External keyboard detected: "Corne Keyboard".

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo "Error: this script only runs on Wayland (WAYLAND_DISPLAY not set)" >&2
  exit 1
fi

KBD_NAME="${KBD_NAME:-AT Translated Set 2 keyboard}"
INHIBIT_FILE="${INHIBIT_FILE:-}"
ACTION="${1:-toggle}"

find_inhibit_file() {
  if [[ -n "$INHIBIT_FILE" ]]; then
    [[ -e "$INHIBIT_FILE" ]] && printf '%s\n' "$INHIBIT_FILE"
    return
  fi

  local event name file
  for event in /sys/class/input/event*; do
    [[ -r "$event/device/name" ]] || continue
    name="$(<"$event/device/name")"
    [[ "$name" == "$KBD_NAME" ]] || continue
    file="$event/device/inhibited"
    [[ -e "$file" ]] && printf '%s\n' "$file" && return
  done
}

usage() {
  echo "Usage: $0 [toggle|disable|enable|status]"
  echo "No argument = toggle"
}

need_sudo_write() {
  local value="$1"
  local file="$2"
  if [[ ! -w "$file" ]]; then
    echo "$value" | sudo tee "$file" >/dev/null
  else
    echo "$value" > "$file"
  fi
}

set_sysfs() {
  local value="$1"
  local file
  file="$(find_inhibit_file)"
  [[ -n "$file" ]] || return 1
  need_sudo_write "$value" "$file"
}


get_status() {
  local file
  file="$(find_inhibit_file)"
  if [[ -n "$file" ]]; then
    case "$(cat "$file")" in
      1) echo "disabled (sysfs inhibited=1)" ;;
      0) echo "enabled (sysfs inhibited=0)" ;;
      *) echo "unknown (sysfs value: $(cat "$file"))" ;;
    esac
    return 0
  fi

  echo "unknown: no sysfs inhibit file found" >&2
  return 1
}

apply() {
  local value="$1"
  if set_sysfs "$value"; then
    get_status
    return 0
  fi
  echo "Error: could not control '$KBD_NAME' via sysfs (Wayland)" >&2
  return 1
}

case "$ACTION" in
  disable) apply 1 ;;
  enable) apply 0 ;;
  toggle)
    file="$(find_inhibit_file)"
    if [[ -n "$file" && "$(cat "$file")" == "1" ]]; then
      apply 0
    else
      apply 1
    fi
    ;;
  status) get_status ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
