#!/usr/bin/env bash
# Polybar audio OUTPUT (sinks) switcher
# - Left click: cycle to next output
# - Right click: menu (rofi/dmenu) with "Type — Device"
# - Shows: "Device Name (max 15 chars)"

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

menu() {
  if have rofi; then
    rofi -dmenu -i -p "$1" -format i
  elif have dmenu; then
    nl -w1 -s' ' | dmenu -i -p "$1" | awk '{print $1-1}'
  else
    echo "Install rofi or dmenu" >&2; exit 1
  fi
}

readarray -t SINKS < <(pactl list short sinks 2>/dev/null | awk '{print $2}')
DEFAULT_SINK="$(pactl info | awk -F': ' '/Default Sink/{print $2}')"

[[ ${#SINKS[@]} -eq 0 ]] && { [[ "${1:-}" =~ ^(next|menu)$ ]] && exit 0 || { echo " N/A"; exit 0; }; }

sink_block() { pactl list sinks | awk -v s="$1" '$0 ~ "Name: " s {f=1} f{print} $0=="" && f{exit}'; }
get_active_port() { sink_block "$1" | awk -F': ' '/Active Port/{print $2}'; }

get_desc() {
  local b; b="$(sink_block "$1")"

  # 1) PipeWire/Pulse property (preferred)
  local dev
  dev=$(printf '%s\n' "$b" | grep -m1 'device.description *=*' | sed -E 's/.*device.description *= *"?([^"]*)".*/\1/')
  if [[ -n "$dev" ]]; then
    echo "$dev"; return
  fi

  # 2) ALSA card name
  local card
  card=$(printf '%s\n' "$b" | grep -m1 'alsa.card_name *=*' | sed -E 's/.*alsa.card_name *= *"?([^"]*)".*/\1/')
  if [[ -n "$card" ]]; then
    echo "$card"; return
  fi

  # 3) Fallback: Description: <text>  → strip the label cleanly
  local desc
  desc=$(printf '%s\n' "$b" | grep -m1 '^[[:space:]]*Description:' | sed -E 's/^[[:space:]]*Description:[[:space:]]*//')
  echo "$desc"
}

is_usb_device() {
  local b; b="$(sink_block "$1")"
  printf '%s\n' "$b" | grep -q 'alsa.driver_name = "snd_usb_audio"'
}

port_short() {
  case "$1" in
    *headphones*|*Headphones*) echo "🎧 Headphones" ;;
    *hdmi*|*Hdmi*)             echo " HDMI" ;;
    *displayport*|*dp*)        echo " DP" ;;
    *lineout*|*line-out*)      echo " Line Out" ;;
    *speaker*)                 echo " Speakers" ;;
    *analog-output*)           echo " Analog" ;;
    *pro-audio*)               echo "🎚️ Pro" ;;
    *)                         echo " Output" ;;
  esac
}

name_short() {
  echo "$1" | sed 's/^alsa_output[.]//; s/[.].*$//' | sed 's/[_-]/ /g' |
  awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}'
}

compose_label() {
  local sink="$1" desc original_desc
  desc="$(get_desc "$sink" || true)"
  [[ -z "$desc" ]] && desc="$(name_short "$sink")"
  
  # Store original length for ellipsis check
  original_desc="$desc"
  
  # Limit description to 15 characters
  desc="${desc:0:15}"
  
  # Add ellipsis if truncated
  if [[ ${#original_desc} -gt 15 ]]; then
    desc="${desc}..."
  fi
  
  echo "$desc"
}

compose_menu_label() {
  local sink="$1" ap desc type
  ap="$(get_active_port "$sink" || true)"
  desc="$(get_desc "$sink" || true)"
  [[ -z "$desc" ]] && desc="$(name_short "$sink")"
  
  # Check if it's a USB device first
  if is_usb_device "$sink"; then
    type=" USB"
  else
    [[ -n "$ap" ]] && type="$(port_short "$ap")" || type=" Output"
  fi
  
  echo "$type — $desc"
}

move_streams() {
  local sink="$1"
  pactl list short sink-inputs | awk '{print $1}' | while read -r si; do
    pactl move-sink-input "$si" "$sink" >/dev/null 2>&1 || true
  done
}

cycle_next() {
  if [[ -z "$DEFAULT_SINK" ]]; then
    pactl set-default-sink "${SINKS[0]}"; move_streams "${SINKS[0]}"; exit 0
  fi
  for i in "${!SINKS[@]}"; do
    if [[ "${SINKS[$i]}" == "$DEFAULT_SINK" ]]; then
      local next="${SINKS[$(( (i+1) % ${#SINKS[@]} ))]}"
      pactl set-default-sink "$next"; move_streams "$next"; break
    fi
  done
}

pick_menu() {
  local LABELS=() idx
  for s in "${SINKS[@]}"; do LABELS+=("$(compose_menu_label "$s")"); done
  idx="$(printf "%s\n" "${LABELS[@]}" | menu "Output")"
  [[ -z "$idx" ]] && exit 0
  sel="${SINKS[$idx]}"; pactl set-default-sink "$sel"; move_streams "$sel"
}

case "${1:-}" in
  next) cycle_next; exit 0 ;;
  menu) pick_menu; exit 0 ;;
esac

DEFAULT_SINK="$(pactl info | awk -F': ' '/Default Sink/{print $2}')"
[[ -z "$DEFAULT_SINK" ]] && { echo " N/A"; exit 0; }

echo "$(compose_label "$DEFAULT_SINK")"