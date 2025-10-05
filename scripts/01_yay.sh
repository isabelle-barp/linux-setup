#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"
source "$ROOT_DIR/lib/yay.sh"

log::section "Instalando/atualizando yay (AUR helper)"
install_yay

log::section "Instalando pacotes AUR (via yay)"
AUR_LIST_FILE="$ROOT_DIR/config/aur-packages.txt"
if [[ -f "$AUR_LIST_FILE" ]]; then
  mapfile -t aur_packages < <(grep -vE '^#|^$' "$AUR_LIST_FILE")
else
  aur_packages=()
fi

if ((${#aur_packages[@]})); then
  aur_install -S --needed "${aur_packages[@]}"
else
  log::info "Nenhum pacote listado em config/aur-packages.txt"
fi
