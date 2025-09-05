#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/pacman.sh"


log::title "Arch Linux Setup"
utils::require_arch
utils::require_internet


export $(grep -v '^#' .env 2>/dev/null | xargs -d '\n' -r) || true


for s in \
  00_pacman \
  01_zsh \
  02_shell_ohmyzsh \
  03_startship \
  08_python \
  10_ly \
  30_podman \
  80_dotfiles \
  90_cleanup
do
  script="$ROOT_DIR/scripts/${s}.sh"
  if [[ -x "$script" ]]; then
    log::section "Running ${s}.sh"
    "$script"
  else
    log::warn "Skipping ${s}.sh (not executable or missing)"
  fi
done


log::success "Setup concluído!"
