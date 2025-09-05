#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"

log::section "Limpeza do sistema"
log::info "Removendo pacotes órfãos..."
if orphans=$(pacman -Qtdq 2>/dev/null); then
  pacq -Rns $orphans
else
  log::info "Nenhum pacote órfão encontrado."
fi

log::info "Limpando cache do pacman..."
pacq -Sc
