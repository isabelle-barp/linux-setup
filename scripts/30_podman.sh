#!/usr/bin/env bash
# Configura Podman no Arch Linux (apenas se já estiver instalado)
# - Configura subuid/subgid para uso rootless
# - Habilita serviços necessários
# - Valida funcionamento básico
# Uso:
#   bash scripts/30_podman.sh

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# ---- Paths e logger do seu repo ----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"

log::section "Configurando Podman"

# ---- Validar se Podman está instalado ----
if command -v podman >/dev/null 2>&1; then
  CURRENT_VERSION=$(podman --version 2>/dev/null || echo "versão desconhecida")
  log::success "Podman encontrado: $CURRENT_VERSION"
  log::info "Prosseguindo com configuração..."
else
  log::error "Podman não está instalado. Por favor, instale o Podman primeiro antes de executar este script."
  log::info "Para instalar: pacman -S podman (ou usando yay/AUR)"
  exit 1
fi

# ---- Verificar disponibilidade do podman-compose ----
if command -v podman-compose >/dev/null 2>&1; then
  log::success "podman-compose disponível: $(podman-compose --version 2>/dev/null || echo 'instalado')"
else
  log::error "Podman Compose não está instalado. Por favor, instale o Podman Compose primeiro antes de executar este script."
  log::info "Para instalar: pacman -S podman-compose (ou usando yay/AUR)"
fi

# ---- Configurações do Podman ----
log::info "Configurando Podman para uso sem root..."

# Verificar se subuid e subgid estão configurados
if ! grep -q "^${USER}:" /etc/subuid 2>/dev/null; then
  log::info "Configurando subuid para usuário $USER..."
  echo "${USER}:100000:65536" | sudo tee -a /etc/subuid >/dev/null
fi

if ! grep -q "^${USER}:" /etc/subgid 2>/dev/null; then
  log::info "Configurando subgid para usuário $USER..."
  echo "${USER}:100000:65536" | sudo tee -a /etc/subgid >/dev/null
fi

# ---- Habilitar e iniciar serviços (opcional para rootless) ----
if systemctl --user list-unit-files podman.socket >/dev/null 2>&1; then
  log::info "Habilitando socket do Podman para o usuário..."
  systemctl --user enable --now podman.socket 2>/dev/null || log::warn "Falha ao habilitar socket do Podman (não crítico)"
fi

# ---- Verificar configuração ----
if command -v podman >/dev/null 2>&1; then
  CONFIGURED_VERSION=$(podman --version)
  log::success "Podman configurado com sucesso: $CONFIGURED_VERSION"

  # Testar funcionamento básico
  log::info "Testando Podman..."
  if podman info >/dev/null 2>&1; then
    log::success "Podman funcionando corretamente"
  else
    log::warn "Podman configurado mas pode precisar de logout/login para funcionar completamente"
  fi

  log::info "Para usar Podman sem sudo, faça logout/login para recarregar as configurações de usuário"
  log::success "Configuração concluída! Execute 'podman --help' para começar a usar."
else
  log::error "Erro inesperado: Podman não encontrado após configuração"
  exit 1
fi