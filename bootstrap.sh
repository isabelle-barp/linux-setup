#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/apt.sh"


log::title "ElementaryOS Setup"
utils::require_distro "elementary" || utils::require_like_ubuntu
utils::require_internet


export $(grep -v '^#' .env 2>/dev/null | xargs -d '\n' -r) || true


for s in \
  00_checks \
  05_repos \
  10_apt \
  20_flatpak \
  25_snap \
  30_devtools \
  33_station \
  34_toolbox \
  35_vscode \
  36_node \
  37_python \
  38_go \
  40_docker \
  45_nomachine \
  50_fonts \
  59_startship \
  60_shell_ohmyzsh \
  61_swap_alt_super \
  62_open_apps_shortcuts \
  63_cmd_shortcuts \
  70_dotfiles \
  80_services \
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
