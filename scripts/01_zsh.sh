#!/usr/bin/env bash
# Define Zsh como shell padrão
# Uso:
#   bash scripts/01_zsh.sh

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"

log::section "Configurando Zsh como shell padrão"

# Instala o Zsh se não estiver presente
if ! command -v zsh >/dev/null 2>&1; then
  log::info "Zsh não encontrado, instalando..."
  smart_install zsh
else
  log::info "Zsh já está instalado"
fi

# Define Zsh como shell padrão
ZSH_BIN="$(command -v zsh)"
CURRENT_SHELL="${SHELL:-}"

if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
  log::info "Alterando shell padrão para: $ZSH_BIN"
  log::info "Pode ser solicitada sua senha..."
  
  if chsh -s "$ZSH_BIN" "$USER"; then
    log::success "Shell padrão alterado para Zsh com sucesso"
    log::info "Execute 'exec zsh' ou abra um novo terminal para usar o Zsh"
  else
    log::error "Falha ao alterar shell padrão automaticamente"
    log::info "Execute manualmente: chsh -s \"$ZSH_BIN\" \"$USER\""
    exit 1
  fi
else
  log::success "Zsh já é o shell padrão"
fi

log::success "Configuração do Zsh concluída"