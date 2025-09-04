#!/usr/bin/env bash
# Instala/atualiza GitHub CLI (gh) em distros baseadas em Ubuntu/Debian
# - Usa repositório oficial do GitHub CLI
# - Idempotente: se já houver gh instalado, apenas confirma/atualiza
# Referência: https://github.com/cli/cli/blob/trunk/docs/install_linux.md

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"
source "$ROOT_DIR/lib/utils.sh"

log::section "Instalando/atualizando GitHub CLI (gh)"

# Requisitos básicos e checagem de distro
utils::require_like_ubuntu
aptq update
aptq install curl ca-certificates gnupg lsb-release >/dev/null || true

# Se já existe, apenas informar e tentar atualizar
if command -v gh >/dev/null 2>&1; then
  log::info "GitHub CLI já instalado: $(gh --version 2>/dev/null | head -n1 || echo 'versão desconhecida')"
fi

# Configurar repositório oficial se ainda não estiver presente
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="$KEYRING_DIR/githubcli-archive-keyring.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/github-cli.list"

if [[ ! -f "$KEYRING_FILE" ]]; then
  log::info "Baixando chave GPG do repositório GitHub CLI…"
  sudo install -m 0755 -d "$KEYRING_DIR"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of="$KEYRING_FILE" 2>/dev/null
  sudo chmod a+r "$KEYRING_FILE"
else
  log::info "Chave GPG já existente em $KEYRING_FILE"
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  log::info "Adicionando repositório APT do GitHub CLI…"
  # Detect distro codename (e.g., focal, jammy) and architecture
  . /etc/os-release || true
  CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-stable}}"
  ARCH_DEB="$(dpkg --print-architecture || echo amd64)"
  echo "deb [arch=${ARCH_DEB} signed-by=${KEYRING_FILE}] https://cli.github.com/packages stable main" | \
    sudo tee "$SOURCE_FILE" >/dev/null
else
  log::info "Repositório já presente em $SOURCE_FILE"
fi

log::info "Atualizando índices APT…"
aptq update

log::info "Instalando/atualizando pacote gh…"
if ! aptq install gh; then
  log::warn "Falha ao instalar gh diretamente. Tentando corrigir dependências…"
  aptq -f install || true
  aptq install gh
fi

if command -v gh >/dev/null 2>&1; then
  VERS=$(gh --version 2>/dev/null | head -n1)
  log::success "GitHub CLI instalado/atualizado com sucesso: $VERS"
else
  log::error "Instalação do GitHub CLI aparentemente falhou."
  exit 1
fi
