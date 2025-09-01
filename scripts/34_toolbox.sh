#!/usr/bin/env bash
# shellcheck disable=SC2155
set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x

# Reexecuta em bash se rodaram com sh/dash
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi

# Trap de erro mais amigável
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: falhou comando: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths robustos (independe da cwd)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Logger (obrigatório: sem fallback)
if [[ ! -r "$ROOT_DIR/lib/log.sh" ]]; then
  echo "[ERROR] logger ausente: $ROOT_DIR/lib/log.sh" >&2
  echo "       verifique se o repo foi clonado corretamente." >&2
  exit 2
fi
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"

log::section "Instalando/atualizando JetBrains Toolboxs"

# --- Dependências ---
aptq update
aptq install curl tar jq desktop-file-utils || true

API_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"

# Consulta a API (objeto com chave TBA -> lista de releases)
DATA="$(curl -fsSL "$API_URL")"
DOWNLOAD_URL="$(jq -r '.TBA[0].downloads.linux.link // empty' <<<"$DATA")"
LATEST_VERSION="$(jq -r '.TBA[0].version // empty' <<<"$DATA")"
BUILD="$(jq -r '.TBA[0].build // empty' <<<"$DATA")"

if [[ -z "$DOWNLOAD_URL" ]]; then
  log::error "API não retornou link de download (caminho .TBA[0].downloads.linux.link)."
  exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

log::info "Baixando Toolbox ${LATEST_VERSION:-?} ${BUILD:+(build $BUILD)}"
curl -fL --retry 3 -o jetbrains-toolbox.tar.gz "$DOWNLOAD_URL"

# Validação do tar.gz (evita HTML/proxy)
if ! tar -tzf jetbrains-toolbox.tar.gz >/dev/null 2>&1; then
  log::error "Arquivo baixado inválido (possível HTML/bloqueio de rede)."
  exit 1
fi

# Captura a primeira entrada do tar sem disparar SIGPIPE com pipefail
first_entry="$(
  tar -tzf jetbrains-toolbox.tar.gz | {
    read -r first || true
    printf '%s\n' "${first%%/*}"
    cat >/dev/null
  }
)"
if [[ -z "$first_entry" ]]; then
  log::error "Pacote vazio ou inválido."
  exit 1
fi
DIR="$first_entry"

tar -xzf jetbrains-toolbox.tar.gz

# Se versão não veio da API, tenta inferir
if [[ -z "$LATEST_VERSION" ]]; then
  LATEST_VERSION="$(sed -nE 's/^jetbrains-toolbox-([0-9.]+).*$/\1/p' <<<"$DIR")"
fi

INSTALL_DIR="/opt/jetbrains-toolbox"
BIN_LINK="/usr/local/bin/jetbrains-toolbox"
VERSION_FILE="$INSTALL_DIR/.version"
BUILD_FILE="$INSTALL_DIR/.build"

installed_ver="$(cat "$VERSION_FILE" 2>/dev/null || true)"
installed_build="$(cat "$BUILD_FILE" 2>/dev/null || true)"

# Idempotência (pula se mesma versão/build, a menos que FORCE)
if [[ -n "${installed_ver}${installed_build}" && "${TOOLBOX_FORCE:-0}" != "1" ]]; then
  if { [[ -n "$LATEST_VERSION" && "$installed_ver" == "$LATEST_VERSION" ]] || [[ -n "$BUILD" && "$installed_build" == "$BUILD" ]]; }; then
    log::info "Já instalado ($installed_ver${installed_build:+, build $installed_build}). Nada a fazer."
    exit 0
  fi
fi

sudo mkdir -p "$INSTALL_DIR"
sudo rm -rf "$INSTALL_DIR"/* 2>/dev/null || true
sudo cp -a "$DIR"/. "$INSTALL_DIR/"

sudo ln -sf "$INSTALL_DIR/bin/jetbrains-toolbox" "$BIN_LINK"

[[ -n "$LATEST_VERSION" ]] && echo "$LATEST_VERSION" | sudo tee "$VERSION_FILE" >/dev/null || true
[[ -n "$BUILD" ]] && echo "$BUILD" | sudo tee "$BUILD_FILE" >/dev/null || true

log::success "Toolbox instalado/atualizado ${LATEST_VERSION:+versão $LATEST_VERSION}${BUILD:+ (build $BUILD)}."

# Cria/atualiza .desktop no usuário
APP_USER_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APP_USER_DIR/jetbrains-toolbox.desktop"

mkdir -p "$APP_USER_DIR"
cat > "$DESKTOP_FILE" <<DESK
[Desktop Entry]
Version=1.0
Type=Application
Name=JetBrains Toolbox
Comment=Manage JetBrains IDEs
Exec=$BIN_LINK %U
Terminal=false
Categories=Development;IDE;
StartupWMClass=jetbrains-toolbox
DESK

chmod 644 "$DESKTOP_FILE"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_USER_DIR" || true

log::success "Atalho do JetBrains Toolbox criado/atualizado no menu."

