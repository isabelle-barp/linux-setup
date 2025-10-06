 #!/usr/bin/env bash
 # Purpose: Hide/disable selected .desktop entries from menus and autostart
 # This script creates user-level overrides so no sudo is required.
 # It sets NoDisplay=true (hide from menus) and Hidden=true (disable autostart)
 # for specific desktop files that don't make sense for this setup.

 set -euo pipefail

 APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
 AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
 SYSTEM_APPS="/usr/share/applications"
 SYSTEM_AUTOSTART="/etc/xdg/autostart"

 mkdir -p "$APPS_DIR" "$AUTOSTART_DIR"

 # Desktop file IDs to hide/disable. Adjust as you like.
 TARGETS=(
   avahi-discover.desktop
   rofi-theme-selector.desktop
   rofi.desktop
   conky.desktop
   picom.desktop
   wheelmap-geo-handler.desktop
   org.gnupg.pinentry-qt.desktop
   org.gnupg.pinentry-qt5.desktop
   openstreetmap-geo-handler.desktop
   Alacritty.desktop
   bssh.desktop
   bvnc.desktop
   qv4l2.desktop
   qvidcap.desktop
   htop.desktop
   mpv.desktop
   electron34.desktop
   electron37.desktop
   ranger.desktop
 )

 log() { printf "[81_desktop_files] %s\n" "$*"; }

 # Copy from src to dest (or create minimal file) and ensure it has Hidden=true and NoDisplay=true
 copy_and_override() {
   local src="$1" dest="$2"
   if [[ -f "$src" ]]; then
     cp -f "$src" "$dest"
   else
     # Create a minimal Desktop Entry if the source doesn't exist
     printf "%s\n" "[Desktop Entry]" "Type=Application" "Name=${dest##*/}" > "$dest"
   fi

   # Remove existing Hidden/NoDisplay lines and append enforced values
   awk '
     BEGIN { IGNORECASE=1 }
     !/^\s*(Hidden|NoDisplay)\s*=/{ print }
     END { print "Hidden=true"; print "NoDisplay=true" }
   ' "$dest" > "$dest.tmp" && mv "$dest.tmp" "$dest"
 }

 for id in "${TARGETS[@]}"; do
   # Menu entry: hide in applications list
   src_app="$SYSTEM_APPS/$id"
   dest_app="$APPS_DIR/$id"
   copy_and_override "$src_app" "$dest_app"
   log "Menu entry hidden: $id"

   # Autostart entry: disable if it exists system-wide or user-wide
   if [[ -f "$SYSTEM_AUTOSTART/$id" || -f "$AUTOSTART_DIR/$id" ]]; then
     src_auto="$SYSTEM_AUTOSTART/$id"
     dest_auto="$AUTOSTART_DIR/$id"
     copy_and_override "$src_auto" "$dest_auto"
     log "Autostart disabled: $id"
   fi

 done

 log "Done. Selected desktop entries have been hidden/disabled via user overrides."