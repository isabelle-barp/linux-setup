#!/usr/bin/env bash
# Instala/atualiza 1Password CLI (op) em distros baseadas em Ubuntu/Debian
# - Usa repositório oficial da 1Password
# - Idempotente: se já houver op instalado e OP_FORCE não estiver setado, só confirma
# Uso:
#   bash scripts/37_1password_cli.sh
# Variáveis:
#   OP_FORCE=1  # força reinstalar/atualizar

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

log::section "Instalando/atualizando 1Password CLI (op)"

# Requisitos básicos
aptq update
aptq install curl ca-certificates gnupg lsb-release >/dev/null || true

# Checagem de distro
utils::require_like_ubuntu

# Se já existe e não forçado, apenas informar
if command -v op >/dev/null 2>&1 && [[ "${OP_FORCE:-0}" != "1" ]]; then
  log::info "1Password CLI já instalado: $(op --version 2>/dev/null || echo 'versão desconhecida')"
else
  # Configura repositório oficial da 1Password
  # Docs: https://developer.1password.com/docs/cli/get-started/#install
  TMP_DIR="$(mktemp -d)"; trap 'rm -rf "$TMP_DIR"' EXIT

  KEYRING_DIR="/etc/apt/keyrings"
  KEYRING_FILE="$KEYRING_DIR/1password.gpg"

  if [[ ! -f "$KEYRING_FILE" ]]; then
    log::info "Baixando chave GPG do repositório 1Password…"
    sudo install -m 0755 -d "$KEYRING_DIR"
    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | \
      sudo gpg --dearmor -o "$KEYRING_FILE"
    sudo chmod a+r "$KEYRING_FILE"
  else
    log::info "Chave GPG já existente em $KEYRING_FILE"
  fi

  # Detectar arquitetura suportada (amd64/arm64)
  ARCH_DEB="$(dpkg --print-architecture || echo amd64)"
  case "$ARCH_DEB" in
    amd64|arm64) ;; 
    *) log::warn "Arquitetura $ARCH_DEB não testada. Tentando mesmo assim." ;;
  esac

  # Criar source list
  SOURCE_FILE="/etc/apt/sources.list.d/1password.list"
  if [[ ! -f "$SOURCE_FILE" ]]; then
    log::info "Adicionando repositório APT da 1Password…"
    echo "deb [arch=${ARCH_DEB} signed-by=${KEYRING_FILE}] https://downloads.1password.com/linux/debian/${ARCH_DEB} stable main" | \
      sudo tee "$SOURCE_FILE" >/dev/null
    # Nota: URL path contém 'amd64' por padrão segundo docs; 1Password usa multi-arch no pacote CLI
  else
    log::info "Repositório já presente em $SOURCE_FILE"
  fi

  # Regras para policy de origem (opcional, recomendado nas docs)
  PREF_FILE="/etc/apt/preferences.d/1password"
  if [[ ! -f "$PREF_FILE" ]]; then
    sudo tee "$PREF_FILE" >/dev/null <<'PREF'
Package: *
Pin: origin downloads.1password.com
Pin-Priority: 1001
PREF
  fi

  log::info "Atualizando índices APT…"
  aptq update

  log::info "Instalando pacote 1password-cli…"
  if ! aptq install 1password-cli; then
    log::warn "Falha via apt-get direto. Tentando corrigir dependências…"
    aptq -f install || true
    aptq install 1password-cli
  fi

  log::success "1Password CLI instalado/atualizado."
fi

# Exibir versão e dicas rápidas
if command -v op >/dev/null 2>&1; then
  V="$(op --version 2>/dev/null || echo 'desconhecida')"
  log::success "Versão: $V"
  log::info "Para fazer login: op signin --account <subdomínio>"
fi
