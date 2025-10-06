#!/usr/bin/env bash
# gtk-clean-all.sh — Cleanup user GTK theme settings to resolve stuck themes (e.g., Nordic).
# Similar to docker-clean-all.sh, but for GTK configs. Removes conflicting files and caches,
# resets GNOME/GTK settings (via gsettings if available), and can optionally reapply a theme.
#
# Usage:
#   gtk-clean-all.sh [--force] [--apply] [--theme NAME] [--icons NAME] [--cursor NAME] [--font NAME]
#
# Defaults when --apply is used:
#   --theme "WhiteSur-Light" --icons "Papirus" --cursor "capitaine-cursors" --font "JetBrains Mono Thin 16"
#
# Notes:
# - Only touches user configuration (HOME). System-wide themes are not modified.
# - If xsettingsd is running, we will send HUP after cleanup; when --apply is used we re-create configs.
# - Safe to run multiple times. Use --force to skip confirmation.

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

say() { echo -e "\e[1;33m-->\e[0m $*"; }
ok() { echo -e "\e[32m✓\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }

confirm() {
  local msg=${1:-"Proceed?"}
  if [[ "${FORCE:-0}" == "1" ]]; then return 0; fi
  read -r -p "$msg [y/N]: " ans || true
  [[ "$ans" =~ ^[Yy]$ ]]
}

FORCE=0
APPLY=0
THEME="WhiteSur-Light"
ICONS="Papirus"
CURSOR="capitaine-cursors"
FONT="JetBrains Mono Thin 16"

while (( "$#" )); do
  case "$1" in
    --force) FORCE=1 ;;
    --apply) APPLY=1 ;;
    --theme) THEME=${2:?missing value for --theme}; shift ;;
    --icons) ICONS=${2:?missing value for --icons}; shift ;;
    --cursor) CURSOR=${2:?missing value for --cursor}; shift ;;
    --font) FONT=${2:?missing value for --font}; shift ;;
    -h|--help)
      sed -n '1,50p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

say "GTK cleanup will remove user theme configs and caches in: $HOME"
if ! confirm "This will remove GTK 2/3/4 user settings, xsettingsd config, some desktop configs, and caches. Continue?"; then
  echo "Aborted."; exit 0
fi

# Track removed files/dirs
removed=()
remove_path() {
  local p="$1"
  if [[ -e "$p" || -L "$p" ]]; then
    rm -rf -- "$p" || true
    removed+=("$p")
  fi
}

# 1) Stop/quiet xsettingsd to avoid re-writing while we clean
if pgrep -x xsettingsd >/dev/null 2>&1; then
  say "Stopping xsettingsd (HUP to reload later)..."
  pkill -TERM xsettingsd || true
  # Give it a moment
  sleep 0.2 || true
fi

# 2) Remove common user theme config files that may pin Nordic or others
remove_path "$HOME/.config/gtk-3.0/settings.ini"
remove_path "$HOME/.config/gtk-4.0/settings.ini"
remove_path "$HOME/.gtkrc-2.0"
remove_path "$HOME/.config/xsettingsd/xsettingsd.conf"

# Desktop/session specific (best-effort)
remove_path "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
remove_path "$HOME/.config/lxsession/LXDE/desktop.conf"
remove_path "$HOME/.config/lxsession/LXQt/desktop.conf"

# 3) Clear caches so GTK/icons re-evaluate
remove_path "$HOME/.cache/gtk-3.0"
remove_path "$HOME/.cache/gtk-4.0"
remove_path "$HOME/.cache/icons"
# pywal cache so next run recolors
remove_path "$HOME/.cache/wal"

ok "User GTK configs and caches cleaned."

# 4) Reset or apply via gsettings if available
if command -v gsettings >/dev/null 2>&1; then
  if (( APPLY == 1 )); then
    say "Applying theme via gsettings: $THEME, icons: $ICONS, cursor: $CURSOR, font: $FONT"
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME" || true
    gsettings set org.gnome.desktop.interface icon-theme "$ICONS" || true
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR" || true
    gsettings set org.gnome.desktop.interface font-name "$FONT" || true
  else
    say "Resetting gsettings theme keys (if set) to defaults"
    gsettings reset-recursively org.gnome.desktop.interface || true
  fi
else
  warn "gsettings not found. Skipping GNOME interface settings."
fi

# 5) Optionally re-create xsettingsd and GTK settings when --apply is provided
if (( APPLY == 1 )); then
  say "Writing fresh xsettingsd and GTK settings..."
  mkdir -p "$HOME/.config/xsettingsd" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
  cat > "$HOME/.config/xsettingsd/xsettingsd.conf" <<EOF
Net/ThemeName "$THEME"
Net/IconThemeName "$ICONS"
Gtk/CursorThemeName "$CURSOR"
Gtk/FontName "$FONT"
EOF
  cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-icon-theme-name=$ICONS
gtk-font-name=$FONT
gtk-cursor-theme-name=$CURSOR
gtk-application-prefer-dark-theme=0
EOF
  # GTK 4 settings (some apps read this)
  cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-icon-theme-name=$ICONS
gtk-font-name=$FONT
gtk-cursor-theme-name=$CURSOR
gtk-application-prefer-dark-theme=0
EOF
  ok "Fresh theme configuration written."
fi

# 6) Reload xsettingsd if present
if command -v xsettingsd >/dev/null 2>&1; then
  # Start or reload xsettingsd in the background (user session)
  if pgrep -x xsettingsd >/dev/null 2>&1; then
    pkill -HUP xsettingsd || true
    ok "xsettingsd reloaded."
  else
    nohup xsettingsd >/dev/null 2>&1 & disown || true
    ok "xsettingsd started."
  fi
else
  warn "xsettingsd not installed; some apps may not pick theme until session restart."
fi

# 7) Summary
if ((${#removed[@]} > 0)); then
  say "Removed paths:"; printf ' - %s\n' "${removed[@]}"
else
  say "Nothing was removed (no conflicting files found)."
fi

ok "GTK cleanup complete."

# 8) Optional guidance to reapply pywal
if command -v wal >/dev/null 2>&1; then
  say "Tip: run 'wal -R' to re-apply last pywal colors, or use scripts/81_theme.sh to apply wallpaper and theme."
fi
