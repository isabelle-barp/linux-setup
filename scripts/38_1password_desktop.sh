#!/usr/bin/env bash
# Instala/atualiza 1Password (Desktop GUI) em distros baseadas em Ubuntu/Debian
# - Usa repositório oficial da 1Password
# - Idempotente: se já houver 1Password e FORCE não estiver setado, só confirma
# Uso:
#   bash scripts/38_1password_desktop.sh
# Variáveis:
#   OP_DESKTOP_FORCE=1  # força reinstalar/atualizar

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

log::section "Instalando/atualizando 1Password Desktop"

# Requisitos básicos
aptq update
aptq install curl ca-certificates gnupg lsb-release >/dev/null || true

# Checagem de distro
utils::require_like_ubuntu

# Se já existe e não forçado, apenas informar
if command -v 1password >/dev/null 2>&1 && [[ "${OP_DESKTOP_FORCE:-0}" != "1" ]]; then
  log::info "1Password já instalado: $(1password --version 2>/dev/null || echo 'versão desconhecida')"
else
  # Configura repositório oficial da 1Password (Desktop)
  # Docs: https://support.1password.com/install-linux/#debian-ubuntu
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

  ARCH_DEB="$(dpkg --print-architecture || echo amd64)"
  case "$ARCH_DEB" in
    amd64|arm64) ;;
    *) log::warn "Arquitetura $ARCH_DEB não testada. Tentando mesmo assim." ;;
  esac

  SOURCE_FILE="/etc/apt/sources.list.d/1password.list"
  if [[ ! -f "$SOURCE_FILE" ]]; then
    log::info "Adicionando repositório APT da 1Password…"
    echo "deb [arch=${ARCH_DEB} signed-by=${KEYRING_FILE}] https://downloads.1password.com/linux/debian/${ARCH_DEB} stable main" | \
      sudo tee "$SOURCE_FILE" >/dev/null
  else
    log::info "Repositório já presente em $SOURCE_FILE"
  fi

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

  log::info "Instalando pacote 1password (Desktop)…"
  if ! aptq install 1password; then
    log::warn "Falha via apt-get direto. Tentando corrigir dependências…"
    aptq -f install || true
    aptq install 1password
  fi

  log::success "1Password Desktop instalado/atualizado."
fi

# Verificar binário e criar/ajustar .desktop do usuário, se necessário
BIN_PATH="$(command -v 1password || true)"
if [[ -z "$BIN_PATH" ]]; then
  # Alguns pacotes expõem como /usr/bin/1password
  BIN_PATH="/usr/bin/1password"
fi

if [[ -x "$BIN_PATH" ]]; then
  APP_DIR="$HOME/.local/share/applications"
  DESK="$APP_DIR/1password.desktop"
  mkdir -p "$APP_DIR"

  # Descobrir ícone provável instalado pelo pacote
  ICON_CANDIDATES=(
    "/usr/share/icons/hicolor/512x512/apps/1password.png"
    "/usr/share/icons/hicolor/256x256/apps/1password.png"
    "/usr/share/pixmaps/1password.png"
  )
  ICON_PATH=""
  for i in "${ICON_CANDIDATES[@]}"; do
    [[ -f "$i" ]] && { ICON_PATH="$i"; break; }
  done

  {
    echo "[Desktop Entry]"
    echo "Version=1.0"
    echo "Type=Application"
    echo "Name=1Password"
    echo "Comment=Password manager"
    echo "Exec=${BIN_PATH} %U"
    [[ -n "$ICON_PATH" ]] && echo "Icon=${ICON_PATH}"
    echo "Terminal=false"
    echo "Categories=Utility;Security;"
    echo "StartupWMClass=1password"
  } > "$DESK"
  chmod 644 "$DESK"
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
  log::success "Atalho criado/atualizado: $DESK"
else
  log::warn "Binário 1password não encontrado após instalação. Verifique o repositório/instalação."
fi

log::success "Pronto! Abra pelo menu ou execute: 1password &"
