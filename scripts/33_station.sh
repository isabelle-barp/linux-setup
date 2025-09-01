#!/usr/bin/env bash
# Instala/atualiza Station no ElementaryOS
# - Preferência: pacote .deb (amd64)
# - Fallback: AppImage (qualquer arquitetura)
# Uso: bash scripts/33_station.sh
set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths do repo e logger (igual aos outros scripts do seu projeto)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

log::section "Instalando/atualizando Station"

# Dependências básicas
sudo apt-get update -y
sudo apt-get install -y curl jq ca-certificates desktop-file-utils || true

API="https://api.github.com/repos/getstation/desktop-app/releases/latest"
DATA="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API")" || {
  log::error "Falha ao consultar as releases do Station (GitHub API)."; exit 1; }

TAG="$(jq -r '.tag_name // empty' <<<"$DATA")"
ARCH="$(dpkg --print-architecture)"

# Tenta achar um .deb da arquitetura (normalmente "Station-amd64.deb")
DEB_URL="$(jq -r --arg arch "$ARCH" '
  .assets[] | select(.name|test("(?i)\\.deb$")) |
  select((.name|test($arch)) or ($arch=="amd64" and .name|test("(?i)amd64"))) |
  .browser_download_url' <<<"$DATA" | head -n1)"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

if [[ -n "$DEB_URL" ]]; then
  log::info "Baixando pacote .deb ${TAG:+($TAG)} para $ARCH"
  curl -fL --retry 3 -o station.deb "$DEB_URL"
  # Instala/atualiza de forma idempotente
  if ! sudo apt-get install -y ./station.deb; then
    # fallback dpkg + fix deps
    sudo dpkg -i station.deb || true
    sudo apt-get -f install -y
  fi
  log::success "Station instalado/atualizado via .deb ${TAG:+$TAG}."
  exit 0
fi

# ---- Fallback: AppImage (qualquer arch) ----
APPIMAGE_URL="$(jq -r '.assets[] | select(.name|test("(?i)AppImage$")) | .browser_download_url' <<<"$DATA" | head -n1)"
if [[ -z "$APPIMAGE_URL" ]]; then
  log::error "Não encontrei .deb nem AppImage compatível para $ARCH nas releases."
  exit 1
fi

INSTALL_DIR="$HOME/.local/opt/station"
BIN_LINK="$HOME/.local/bin/station"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$INSTALL_DIR" "$HOME/.local/bin" "$APP_DIR"

log::info "Baixando AppImage ${TAG:+($TAG)}"
curl -fL --retry 3 -o "$INSTALL_DIR/Station.AppImage" "$APPIMAGE_URL"
chmod +x "$INSTALL_DIR/Station.AppImage"
ln -sf "$INSTALL_DIR/Station.AppImage" "$BIN_LINK"

# .desktop básico (ícone genérico, sem Icon=)
cat > "$APP_DIR/station.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Station
Exec=$BIN_LINK %U
Terminal=false
Categories=Network;Office;
EOF
chmod 644 "$APP_DIR/station.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true

log::success "Station instalado via AppImage (fallback). Abra com: station &"
