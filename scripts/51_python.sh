#!/usr/bin/env bash
set -euo pipefail

# Instala Python 3 e pipx (se necessário) e prepara ambiente para instalar ferramentas via pipx

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"
source "$ROOT_DIR/lib/utils.sh"

log::section "Instalando Python e pipx (se necessário)"

# Garante que é um sistema baseado em Ubuntu/Elementary
utils::require_like_ubuntu

# Atualiza cache APT silenciosamente (se necessário)
log::info "Atualizando lista de pacotes"
aptoq update

# Pacotes básicos para Python e pipx
PACKAGES=(python3 python3-venv python3-pip pipx)

log::info "Instalando pacotes: ${PACKAGES[*]}"
aptoq install "${PACKAGES[@]}" || true

# pipx pode não criar o shim se não houver ~/.local/bin no PATH. Garantimos isso.
# Em algumas distros, o binário pipx fica em /usr/bin/pipx, mas ainda assim é bom ajustar PATH local
if ! grep -q "~/.local/bin" <<<"${PATH}"; then
  SHELL_RC="${HOME}/.bashrc"
  # Se o usuário usa zsh (oh-my-zsh), também adicionamos ao .zshrc
  if [[ -n ${ZSH_VERSION:-} || -d "$HOME/.oh-my-zsh" ]]; then
    SHELL_RC_ZSH="${HOME}/.zshrc"
  fi
  log::info "Garantindo ~/.local/bin no PATH do shell"
  mkdir -p "$HOME/.local/bin"
  if [[ -w "$SHELL_RC" ]]; then
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  else
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  fi
  if [[ -n ${SHELL_RC_ZSH:-} ]]; then
    if [[ -w "$SHELL_RC_ZSH" ]]; then
      grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC_ZSH" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC_ZSH"
    else
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC_ZSH"
    fi
  fi
fi

# Garante que pipx funcione (repara links de shims)
if command -v pipx &>/dev/null; then
  pipx ensurepath || true
else
  log::warn "pipx não encontrado no PATH após instalação. Tentando via pip."
  python3 -m pip install --user --upgrade pipx || true
  "$HOME/.local/bin/pipx" ensurepath || true
fi

log::success "Python e pipx verificados/instalados."
