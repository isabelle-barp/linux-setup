#!/usr/bin/env bash
# Link user-scripts commands into ~/.local/bin and add zsh convenience command.
# Usage:
#   bash scripts/20_user_scripts.sh
#
set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

BIN_DIR="$HOME/.local/bin"
US_DIR="$ROOT_DIR/user-scripts"

log::section "Instalando comandos personalizados (user-scripts)"

mkdir -p "$BIN_DIR"

link_cmd() {
  local src="$1" name="$2"
  if [[ ! -x "$src" ]]; then
    chmod +x "$src" || true
  fi
  local dst="$BIN_DIR/$name"
  if [[ -L "$dst" || -f "$dst" ]]; then
    if [[ "$(readlink -f "$dst" || true)" == "$(readlink -f "$src")" ]]; then
      log::info "$name já linkado em $dst"
      return 0
    fi
    log::info "Atualizando link: $dst"
    rm -f -- "$dst"
  fi
  ln -s -- "$src" "$dst"
  log::success "Link criado: $dst -> $src"
}

# Docker cleanup tool
if [[ -f "$US_DIR/docker-clean-all.sh" ]]; then
  link_cmd "$US_DIR/docker-clean-all.sh" "docker-nuke"
else
  log::warn "Script ausente: $US_DIR/docker-clean-all.sh"
fi

# Ensure ~/.local/bin is on PATH via ~/.zshrc and add a convenience alias (idempotent)
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]]; then
  if ! grep -q '\.local/bin' "$ZSHRC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    log::info "Adicionado ~/.local/bin ao PATH no ~/.zshrc"
  fi
  if ! grep -qE '^alias docker-nuke=' "$ZSHRC"; then
    echo 'alias docker-nuke="$HOME/.local/bin/docker-nuke"' >> "$ZSHRC"
    log::success "Alias docker-nuke adicionado ao ~/.zshrc"
  else
    log::info "Alias docker-nuke já presente no ~/.zshrc"
  fi
else
  log::warn "~/.zshrc não encontrado. Após configurar Zsh, reexecute este script para adicionar o alias."
fi

log::success "Comandos personalizados instalados."