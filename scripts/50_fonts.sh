#!/usr/bin/env bash
# Instala fontes para o seu setup (Nerd Fonts + Emoji + Powerline fallback)
# e, opcionalmente, Fira Code ORIGINAL via GitHub (tonsky/FiraCode).
#
# Uso:
#   bash scripts/50_fonts.sh
#
# Variáveis opcionais:
#   FONTS="JetBrainsMono FiraCode CaskaydiaCove SymbolsOnly"   # Nerd Fonts a instalar
#   FIRA_CODE_ORIGINAL=1                                       # instala Fira Code original (GitHub)
#   SET_TERMINAL_FONT="JetBrainsMono Nerd Font 12"              # define fonte do Terminal (opcional)
#   SYSTEM_WIDE=0                                               # 1 = instala em /usr/local/share/fonts
#   INSTALL_EMOJI=1                                             # instala fonts-noto-color-emoji (default: 1)
#   INSTALL_POWERLINE=1                                         # instala fonts-powerline (default: 1)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# --- Paths/logger do seu repo ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

log::section "Instalando fontes (Nerd Fonts + Emoji + Powerline)"

# --- Config padrão ---
FONTS="${FONTS:-JetBrainsMono FiraCode CaskaydiaCove SymbolsOnly}"
NF_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
SYSTEM_WIDE="${SYSTEM_WIDE:-0}"
FIRA_CODE_ORIGINAL="${FIRA_CODE_ORIGINAL:-0}"
INSTALL_EMOJI="${INSTALL_EMOJI:-1}"
INSTALL_POWERLINE="${INSTALL_POWERLINE:-1}"

if [[ "$SYSTEM_WIDE" == "1" ]]; then
  DEST_NF="/usr/local/share/fonts/NerdFonts"
  DEST_ORIG="/usr/local/share/fonts"
else
  DEST_NF="$HOME/.local/share/fonts/NerdFonts"
  DEST_ORIG="$HOME/.local/share/fonts"
fi

# --- Dependências base ---
sudo apt-get update -y
sudo apt-get install -y fontconfig unzip curl ca-certificates || true

# Emoji e Powerline (APT)
if [[ "$INSTALL_EMOJI" == "1" ]]; then
  log::info "Instalando emoji colorido (fonts-noto-color-emoji)…"
  sudo apt-get install -y fonts-noto-color-emoji || true
fi
if [[ "$INSTALL_POWERLINE" == "1" ]]; then
  log::info "Instalando fontes powerline (fallback)…"
  sudo apt-get install -y fonts-powerline || true
fi

# --- Helpers ---
ensure_dir() { [[ "$SYSTEM_WIDE" == "1" ]] && sudo mkdir -p "$1" || mkdir -p "$1"; }
copy_into()  { [[ "$SYSTEM_WIDE" == "1" ]] && sudo cp -a "$1" "$2" || cp -a "$1" "$2"; }

install_nf_zip() {
  local name="$1" zip="$2" tmp
  tmp="$(mktemp -d)"
  log::info "Baixando $name Nerd Font…"
  if ! curl -fL --retry 3 -o "$tmp/$name.zip" "$zip"; then
    log::warn "Falhou download de $name ($zip). Pulando."
    rm -rf "$tmp"; return 0
  fi
  log::info "Extraindo $name…"
  (cd "$tmp" && unzip -q "$name.zip") || true
  mapfile -t files < <(find "$tmp" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print)
  if (( ${#files[@]} == 0 )); then
    log::warn "Nenhum .ttf/.otf encontrado para $name. Pulando."
    rm -rf "$tmp"; return 0
  fi
  ensure_dir "$DEST_NF/$name"
  for f in "${files[@]}"; do copy_into "$f" "$DEST_NF/$name/"; done
  rm -rf "$tmp"
  log::success "$name (Nerd Font) instalada em $DEST_NF/$name"
}

already_has_nf() {
  local name="$1"
  find "$DEST_NF/$name" -type f \( -iname '*.ttf' -o -iname '*.otf' \) >/dev/null 2>&1
}

install_firacode_original_github() {
  # Fira Code ORIGINAL (sem patch Nerd) da release mais recente
  local api="https://api.github.com/repos/tonsky/FiraCode/releases/latest" tmp url
  tmp="$(mktemp -d)"
  log::info "Consultando release mais recente da Fira Code (GitHub)…"
  rel="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api" || true)"
  url="$(printf '%s' "$rel" | grep -oE 'https://github.com/tonsky/FiraCode/releases/download/[^"]+/Fira_Code_v[^"]+\.zip' | head -n1 || true)"
  if [[ -z "$url" ]]; then
    log::warn "Não encontrei asset .zip da Fira Code na release. Pulando."
    rm -rf "$tmp"; return 0
  fi
  log::info "Baixando Fira Code original…"
  curl -fL --retry 3 -o "$tmp/FiraCode.zip" "$url"
  log::info "Extraindo Fira Code…"
  (cd "$tmp" && unzip -q FiraCode.zip) || true
  local dest="$DEST_ORIG/FiraCode"
  ensure_dir "$dest"
  mapfile -t files < <(find "$tmp" -type f \( -path '*/ttf/*.ttf' -o -iname 'FiraCode-*.ttf' \) -print)
  if (( ${#files[@]} == 0 )); then
    log::warn "Nenhum .ttf encontrado na Fira Code original."
    rm -rf "$tmp"; return 0
  fi
  for f in "${files[@]}"; do copy_into "$f" "$dest/"; done
  rm -rf "$tmp"
  log::success "Fira Code ORIGINAL instalada em $dest"
}

# --- Instalação Nerd Fonts selecionadas ---
ensure_dir "$DEST_NF"
for font in $FONTS; do
  case "$font" in
    JetBrainsMono) NAME="JetBrainsMono"; ZIP="$NF_BASE/JetBrainsMono.zip" ;;
    FiraCode)      NAME="FiraCode";      ZIP="$NF_BASE/FiraCode.zip" ;;
    CaskaydiaCove|CascadiaCode) NAME="CaskaydiaCove"; ZIP="$NF_BASE/CaskaydiaCove.zip" ;;
    Hack)          NAME="Hack";          ZIP="$NF_BASE/Hack.zip" ;;
    Meslo)         NAME="Meslo";         ZIP="$NF_BASE/Meslo.zip" ;;
    SymbolsOnly|NerdFontsSymbolsOnly|Symbols) NAME="NerdFontsSymbolsOnly"; ZIP="$NF_BASE/NerdFontsSymbolsOnly.zip" ;;
    *) log::warn "Fonte desconhecida em FONTS: $font (pulando)"; continue ;;
  esac
  if already_has_nf "$NAME"; then
    log::info "$NAME (Nerd Font) já presente em $DEST_NF/$NAME"
  else
    install_nf_zip "$NAME" "$ZIP"
  fi
done

# --- Fira Code ORIGINAL (GitHub), se solicitado ---
if [[ "$FIRA_CODE_ORIGINAL" == "1" ]]; then
  install_firacode_original_github
fi

# --- Atualiza cache de fontes ---
log::info "Atualizando cache de fontes…"
if [[ "$SYSTEM_WIDE" == "1" ]]; then
  sudo fc-cache -fv >/dev/null
else
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null
fi
log::success "Cache atualizado."

# --- (Opcional) Define a fonte do Terminal do Elementary ---
if [[ -n "${SET_TERMINAL_FONT:-}" ]]; then
  if gsettings writable io.elementary.terminal.settings font >/dev/null 2>&1; then
    log::info "Definindo fonte do Terminal para: $SET_TERMINAL_FONT"
    gsettings set io.elementary.terminal.settings font "$SET_TERMINAL_FONT" || \
      log::warn "Não foi possível aplicar a fonte ao Terminal (gsettings)."
  else
    log::warn "Chave do Terminal não disponível (pule se não usa o terminal do Elementary)."
  fi
fi

log::success "Fontes prontas! Selecione uma Nerd Font **Mono** no terminal/editor (ex.: JetBrainsMono Nerd Font Mono)."
