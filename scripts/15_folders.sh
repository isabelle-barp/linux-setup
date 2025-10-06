#!/usr/bin/env bash
# Create common home folders mirroring the structure used in this setup.
# Idempotent: safe to run multiple times. Only creates directories if missing.
# Usage:
#   bash scripts/15_folders.sh

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

log::section "Creating user folders"

# Base XDG-like directories commonly used
XDG_DIRS=(
  "$HOME/Desktop"
  "$HOME/Documents"
  "$HOME/Downloads"
  "$HOME/Music"
  "$HOME/Pictures"
  "$HOME/Videos"
  "$HOME/Templates"
  "$HOME/Public"
)

# Development tree as used by this repository path
DEV_DIRS=(
  "$HOME/Source"
  "$HOME/Source/Code"
  "$HOME/Source/Code/Personal"
)

# Dirs referenced elsewhere in this repo
OTHER_DIRS=(
  "$HOME/Images"
  "$HOME/Pictures/Wallpapers"
  "$HOME/Pictures/Assets"
  "$HOME/Pictures/Screenshots"
  "$HOME/.local/bin"
)

create_dirs() {
  local created=0 skipped=0
  for d in "$@"; do
    if [[ -d "$d" ]]; then
      log::info "exists: $d"
      ((skipped++)) || true
    else
      mkdir -p -- "$d"
      log::success "created: $d"
      ((created++)) || true
    fi
  done
  log::info "Summary: created=$created skipped=$skipped"
}

create_dirs "${XDG_DIRS[@]}"
create_dirs "${DEV_DIRS[@]}"
create_dirs "${OTHER_DIRS[@]}"

log::success "User folders ensured."