#!/usr/bin/env bash
# Instala/atualiza GitKraken no ElementaryOS (Ubuntu-like)
# - Somente .deb oficial (amd64)
# - Cria/atualiza o .desktop no usuário
# Uso:
#   bash scripts/32_gitkraken.sh
# Variáveis:
#   GITKRAKEN_FORCE=1          # força reinstalar mesmo se já houver
#   GITKRAKEN_DEB_URL="<url>"  # usar URL custom do .deb (opcional)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# ---- Paths e logger do seu repo ----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"

log::section "Instalando/atualizando GitKraken (.deb)"

# ---- Pré-requisitos ----
aptq update
aptq install curl wget ca-certificates desktop-file-utils || true

ARCH="$(dpkg --print-architecture || echo unknown)"
if [[ "$ARCH" != "amd64" ]]; then
  log::error "Arquitetura '$ARCH' não suportada pelo .deb oficial (requer amd64)."
  exit 1
fi

# ---- Idempotência: se já existe, opcionalmente só renova o .desktop ----
if command -v gitkraken >/dev/null 2>&1 && [[ "${GITKRAKEN_FORCE:-0}" != "1" ]]; then
  log::info "GitKraken já instalado: $(gitkraken --version 2>/dev/null || echo 'versão desconhecida')"
  SKIP_INSTALL=1
else
  SKIP_INSTALL=0
fi

# ---- Download + instalação (.deb) ----
DEB_URL="${GITKRAKEN_DEB_URL:-https://release.gitkraken.com/linux/gitkraken-amd64.deb}"
if [[ "$SKIP_INSTALL" == "0" ]]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  cd "$TMP"
  log::info "Baixando .deb do GitKraken…"
  wget -q --show-progress -O gitkraken.deb "$DEB_URL"

  log::info "Instalando pacote (.deb)…"
  if ! aptq install ./gitkraken.deb; then
    log::info "Tentando via dpkg + correção de dependências…"
    sudo dpkg -i gitkraken.deb || true
    aptq -f install
  fi
  log::success "GitKraken instalado/atualizado via .deb."
fi

# ---- Descobrir caminho do executável para usar no .desktop ----
BIN_PATH="$(command -v gitkraken || true)"
if [[ -z "$BIN_PATH" ]]; then
  # fallback comum do pacote .deb
  BIN_PATH="/usr/bin/gitkraken"
fi

# ---- Detectar ícone (opcional) ----
ICON_CANDIDATES=(
  "/usr/share/pixmaps/gitkraken.png"
  "/usr/share/icons/hicolor/512x512/apps/gitkraken.png"
  "/usr/share/icons/hicolor/256x256/apps/gitkraken.png"
  "/usr/share/icons/hicolor/128x128/apps/gitkraken.png"
  "/usr/share/gitkraken/gitkraken.png"
)
ICON_PATH=""
for i in "${ICON_CANDIDATES[@]}"; do
  [[ -f "$i" ]] && { ICON_PATH="$i"; break; }
done

# ---- Criar/atualizar .desktop no usuário ----
APP_DIR="$HOME/.local/share/applications"
DESK="$APP_DIR/gitkraken.desktop"
mkdir -p "$APP_DIR"

{
  echo "[Desktop Entry]"
  echo "Version=1.0"
  echo "Type=Application"
  echo "Name=GitKraken"
  echo "Comment=The legendary Git GUI client"
  echo "Exec=${BIN_PATH} %U"
  [[ -n "$ICON_PATH" ]] && echo "Icon=${ICON_PATH}"
  echo "Terminal=false"
  echo "Categories=Development;IDE;"
  echo "StartupWMClass=gitkraken"
} > "$DESK"

chmod 644 "$DESK"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true

log::success "Atalho criado/atualizado: $DESK"
log::success "Pronto! Abra pelo menu ou execute: gitkraken &"
