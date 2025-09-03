#!/usr/bin/env bash
# Instala/atualiza Obsidian no ElementaryOS/Ubuntu-like
# Preferência: pacote .deb oficial (amd64); Fallback: AppImage
# Uso:
#   bash scripts/35_obsidian.sh
# Variáveis:
#   OBSIDIAN_FORCE=1          # força reinstalar mesmo se já houver
#   OBSIDIAN_DEB_URL="<url>"  # usar URL custom do .deb (opcional)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths do repo e helpers
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"

log::section "Instalando/atualizando Obsidian"

# Dependências básicas
aptq update
aptq install curl wget jq ca-certificates desktop-file-utils || true

# Idempotência
if command -v obsidian >/dev/null 2>&1 && [[ "${OBSIDIAN_FORCE:-0}" != "1" ]]; then
  log::info "Obsidian já instalado: $(obsidian --version 2>/dev/null || echo 'versão desconhecida')"
  SKIP_INSTALL=1
else
  SKIP_INSTALL=0
fi

ARCH="$(dpkg --print-architecture || echo unknown)"

# 1) Tenta .deb oficial (apenas amd64 disponível publicamente)
DEB_URL="${OBSIDIAN_DEB_URL:-}"
if [[ -z "$DEB_URL" ]]; then
  if [[ "$ARCH" == "amd64" ]]; then
    # Página de downloads aponta para latest Obsidian-x.y.z.AppImage/.deb
    # A API de releases do GitHub do obsidianmd/obsidian-releases requer scraping básico
    API="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
    if DATA="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API" 2>/dev/null)"; then
      DEB_URL="$(jq -r '.assets[] | select(.name|test("(?i)\\.deb$")) | .browser_download_url' <<<"$DATA" | head -n1)"
    fi
    # Fallback hardcoded URL pattern (pode mudar no futuro)
    if [[ -z "$DEB_URL" ]]; then
      # Muitas distros usam esse mirror, tentaremos o CDN do GitHub se falhar
      DEB_URL=""
    fi
  fi
fi

if [[ "$SKIP_INSTALL" == "0" && -n "$DEB_URL" ]]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  cd "$TMP"
  log::info "Baixando pacote .deb do Obsidian ($ARCH)"
  wget -q --show-progress -O obsidian.deb "$DEB_URL"
  log::info "Instalando pacote (.deb)…"
  if ! aptq install ./obsidian.deb; then
    sudo dpkg -i obsidian.deb || true
    aptq -f install
  fi
  log::success "Obsidian instalado/atualizado via .deb."
fi

# Verifica se o binário existe (via .deb geralmente é /usr/bin/obsidian)
BIN_PATH="$(command -v obsidian || true)"
if [[ -z "$BIN_PATH" ]]; then
  # 2) Fallback: AppImage (qualquer arch)
  API="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
  DATA="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API" || true)"
  APPIMAGE_URL="$(jq -r '.assets[] | select(.name|test("(?i)AppImage$")) | .browser_download_url' <<<"$DATA" | head -n1)"
  if [[ -z "$APPIMAGE_URL" ]]; then
    log::error "Não foi possível encontrar pacote .deb ou AppImage para Obsidian."
    exit 1
  fi
  INSTALL_DIR="$HOME/.local/opt/obsidian"
  BIN_LINK="$HOME/.local/bin/obsidian"
  APP_DIR="$HOME/.local/share/applications"
  mkdir -p "$INSTALL_DIR" "$HOME/.local/bin" "$APP_DIR"
  log::info "Baixando AppImage do Obsidian"
  curl -fL --retry 3 -o "$INSTALL_DIR/Obsidian.AppImage" "$APPIMAGE_URL"
  chmod +x "$INSTALL_DIR/Obsidian.AppImage"
  ln -sf "$INSTALL_DIR/Obsidian.AppImage" "$BIN_LINK"
  BIN_PATH="$BIN_LINK"
fi

# Ícone: tenta localizar ícone instalado pelo .deb; senão deixa sem Icon
ICON_CANDIDATES=(
  "/usr/share/icons/hicolor/512x512/apps/obsidian.png"
  "/usr/share/icons/hicolor/256x256/apps/obsidian.png"
  "/usr/share/pixmaps/obsidian.png"
  "/usr/share/icons/hicolor/512x512/apps/obsidian.png"
)
ICON_PATH=""
for i in "${ICON_CANDIDATES[@]}"; do
  [[ -f "$i" ]] && { ICON_PATH="$i"; break; }
done

# Cria/atualiza .desktop
APP_DIR="$HOME/.local/share/applications"
DESK="$APP_DIR/obsidian.desktop"
mkdir -p "$APP_DIR"
{
  echo "[Desktop Entry]"
  echo "Version=1.0"
  echo "Type=Application"
  echo "Name=Obsidian"
  echo "Comment=Knowledge base and note-taking"
  echo "Exec=${BIN_PATH} %U"
  [[ -n "$ICON_PATH" ]] && echo "Icon=${ICON_PATH}"
  echo "Terminal=false"
  echo "Categories=Office;Utility;"
  echo "StartupWMClass=obsidian"
} > "$DESK"
chmod 644 "$DESK"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true

log::success "Atalho criado/atualizado: $DESK"
log::success "Pronto! Abra pelo menu ou execute: obsidian &"
