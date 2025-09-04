#!/usr/bin/env bash
set -euo pipefail

# Instala o Aider (https://aider.chat). Requer Python/pipx (instalados por 51_python.sh).

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"

log::section "Instalando Aider via pipx"

utils::require_like_ubuntu

# Verifica pipx
if ! command -v pipx &>/dev/null; then
  log::warn "pipx não está disponível no PATH. Execute o script 51_python.sh ou rode o bootstrap. Tentando ajustar PATH e continuar."
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v pipx &>/dev/null; then
  log::error "pipx ainda não encontrado. Abortando instalação do Aider."
  exit 1
fi

# Nome do pacote do Aider. Usaremos o meta pacote 'aider-chat' (recomendado) e com extras comuns.
AIDER_PKG="aider-chat[openai,anthropic,gemini,groq]"

# Se já instalado, atualiza; senão instala
if pipx list | grep -qE "^package +aider-chat "; then
  log::info "Aider já instalado. Atualizando para a última versão..."
  pipx upgrade aider-chat || {
    log::warn "Falha ao atualizar via pipx upgrade. Tentando reinstalar."
    pipx uninstall aider-chat || true
    pipx install "$AIDER_PKG" --include-deps
  }
else
  log::info "Instalando Aider..."
  pipx install "$AIDER_PKG" --include-deps
fi

# Verifica binário
if command -v aider &>/dev/null; then
  log::success "Aider instalado com sucesso: $(aider --version 2>/dev/null || echo 'versão verificada')"
else
  log::warn "O binário 'aider' não está no PATH ainda. Executando pipx ensurepath."
  pipx ensurepath || true
  if ! command -v aider &>/dev/null; then
    log::error "Instalação aparentemente concluída mas 'aider' não está acessível no PATH. Reinicie o shell ou adicione ~/.local/bin ao PATH."
    exit 1
  fi
fi

# Dicas de uso
log::info "Dica: configure sua(s) API key(s) como variáveis de ambiente, por exemplo:"
log::info "  export OPENAI_API_KEY=..."
log::info "  export ANTHROPIC_API_KEY=..."
log::info "  export GEMINI_API_KEY=..."
log::info "  export GROQ_API_KEY=..."
log::info "Para iniciar: 'aider .' dentro do repositório que deseja usar."