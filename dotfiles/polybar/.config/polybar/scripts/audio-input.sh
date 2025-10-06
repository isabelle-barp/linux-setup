#!/usr/bin/env bash
# Polybar audio INPUT (sources) switcher
# - Left click: cycle to next mic
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

readarray -t ALL < <(pactl list short sources | awk '{print $2}')
readarray -t SOURCES < <(printf "%s\n" "${ALL[@]}" | grep -v '\.monitor$')
DEFAULT_SRC="$(pactl info | awk -F': ' '/Default Source/{print $2}')"

[[ ${#SOURCES[@]} -eq 0 ]] && { [[ "${1:-}" =~ ^(next|menu)$ ]] && exit 0 || { echo " N/A"; exit 0; }; }

src_block() { pactl list sources | awk -v s="$1" '$0 ~ "Name: " s {f=1} f{print} $0=="" && f{exit}'; }
get_active_port() { src_block "$1" | awk -F': ' '/Active Port/{print $2}'; }

get_desc() {
  local b; b="$(src_block "$1")"

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
  local b; b="$(src_block "$1")"
  printf '%s\n' "$b" | grep -q 'alsa.driver_name = "snd_usb_audio"'
}

port_short() {
  case "$1" in
    *headset*|*mic*|*Mic*) echo " Mic" ;;
    *linein*|*line-in*|*built-in*)   echo " Line In" ;;
    *hdmi*|*Hdmi*)        echo "🖥️ HDMI In" ;;
    *displayport*|*dp*)   echo "🖥️ DP In" ;;
    *)                    echo "🎤 Mic" ;;
  esac
}

name_short() {
  echo "$1" | sed 's/^alsa_input[.]//; s/[.].*$//' | sed 's/[_-]/ /g' |
  awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}'
}

compose_label() {
  local src="$1" desc original_desc
  desc="$(get_desc "$src" || true)"
  [[ -z "$desc" ]] && desc="$(name_short "$src")"
  
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
  local src="$1" ap desc type
  ap="$(get_active_port "$src" || true)"
  desc="$(get_desc "$src" || true)"
  [[ -z "$desc" ]] && desc="$(name_short "$src")"
  
  # Check if it's a USB device first
  if is_usb_device "$src"; then
    type=" USB"
  else
    [[ -n "$ap" ]] && type="$(port_short "$ap")" || type="000F02CB Mic"
  fi
  
  echo "$type — $desc"
}

cycle_next() {
  if [[ -z "$DEFAULT_SRC" ]]; then
    pactl set-default-source "${SOURCES[0]}"; exit 0
  fi
  for i in "${!SOURCES[@]}"; do
    if [[ "${SOURCES[$i]}" == "$DEFAULT_SRC" ]]; then
      local next="${SOURCES[$(( (i+1) % ${#SOURCES[@]} ))]}"
      pactl set-default-source "$next"; break
    fi
  done
}

pick_menu() {
  local LABELS=() idx
  for s in "${SOURCES[@]}"; do LABELS+=("$(compose_menu_label "$s")"); done
  idx="$(printf "%s\n" "${LABELS[@]}" | menu "Input")"
  [[ -z "$idx" ]] && exit 0
  sel="${SOURCES[$idx]}"; pactl set-default-source "$sel"
}

case "${1:-}" in
  next) cycle_next; exit 0 ;;
  menu) pick_menu; exit 0 ;;
esac

DEFAULT_SRC="$(pactl info | awk -F': ' '/Default Source/{print $2}')"
[[ -z "$DEFAULT_SRC" ]] && { echo " N/A"; exit 0; }

echo "$(compose_label "$DEFAULT_SRC")"