#!/usr/bin/env bash
set -euo pipefail

# Instala o editor Cursor no Arch Linux (prioriza AUR cursor-bin)
# Uso direto:
#   bash scripts/20_cursor.sh
# Requisitos: internet e Arch Linux

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/pacman_official.sh"
source "$ROOT_DIR/lib/yay.sh"

utils::require_arch
utils::require_internet

log::section "Instalando Cursor (Editor)"

# Possíveis nomes de pacote
CANDIDATES=(
  "cursor-bin"   # AUR binário (recomendado)
  "cursor"       # AUR a partir do fonte
)

installed=false

# Se já existir, apenas informa
if command -v cursor >/dev/null 2>&1; then
  log::success "Cursor já está instalado: $(command -v cursor)"
  installed=true
else
  # Tenta instalar (prefere oficial se existir, senão AUR via yay)
  for pkg in "${CANDIDATES[@]}"; do
    if is_official_package "$pkg"; then
      log::info "Tentando instalar pacote oficial: $pkg"
      pacq -S --needed "$pkg" || true
    elif is_aur_package "$pkg"; then
      log::info "Tentando instalar pacote AUR: $pkg"
      aur_install -S --needed "$pkg" || true
    else
      log::warn "Pacote não encontrado em repo oficial nem AUR: $pkg"
      continue
    fi

    if command -v cursor >/dev/null 2>&1; then
      log::success "Cursor instalado com sucesso via: $pkg"
      installed=true
      break
    fi
  done
fi

if ! $installed; then
  log::error "Não foi possível instalar o Cursor automaticamente. Verifique sua conexão e o AUR."
  log::info "Você pode tentar manualmente:"
  log::info "  - Instalar yay (se necessário) e rodar: yay -S cursor-bin"
  exit 1
fi

# Dica de execução
log::info "Para abrir o Cursor pelo terminal: cursor"
log::success "Instalação do Cursor finalizada"