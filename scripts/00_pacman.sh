#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"


log::section "Pacman update/upgrade"
pacq -Syu


log::section "Instalando pacotes Pacman (repositórios oficiais)"
mapfile -t packages < <(grep -vE '^#|^$' "$ROOT_DIR/config/pacman-packages.txt")
if ((${#packages[@]})); then
  pacq -S --needed "${packages[@]}"
else
  log::info "Nenhum pacote listado em config/pacman-packages.txt"
fi