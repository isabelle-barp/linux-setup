#!/usr/bin/env bash
# Instala e configura tema GTK (WhiteSur-Light) e ícones (Papirus), cria pastas de imagens
# e executa pywal para aplicar paleta baseada no papel de parede.
# Requisitos: Arch Linux (pacman) + yay (AUR helper será instalado se necessário)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"

log::section "Theme setup (GTK + Icons + pywal)"
utils::require_arch

# Pastas para imagens/temas do usuário
WALL_DIR="$HOME/Images/Wallpapers"
ASSETS_DIR="$HOME/Images/Assets"
mkdir -p -- "$WALL_DIR" "$ASSETS_DIR"
log::info "Pastas garantidas: $WALL_DIR, $ASSETS_DIR"

# Copia wallpapers do repositório para a pasta do usuário (não sobrescreve existentes)
SRC_WALL="$ROOT_DIR/pictures/wallpapers"
if [[ -d "$SRC_WALL" ]]; then
  mkdir -p -- "$WALL_DIR"
  # copia conteúdo da pasta (arquivos e subpastas) de forma recursiva e sem sobrescrever
  cp -r -n "$SRC_WALL"/. "$WALL_DIR"/ 2>/dev/null || true
  log::info "Wallpapers copiados de $SRC_WALL para $WALL_DIR (sem sobrescrever existentes)"
else
  log::warn "Diretório de wallpapers do repositório não encontrado: $SRC_WALL"
fi


# Aplica tema GTK e ícones via xsettingsd (se presente) e gtk settings
THEME_NAME="WhiteSur-Light"
ICON_NAME="Papirus"
CURSOR_NAME="capitaine-cursors"
GTK_FONT="JetBrains Mono Thin 16"

# Atualiza ~/.config/xsettingsd/xsettingsd.conf
XSD_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
mkdir -p -- "$(dirname -- "$XSD_CONF")"
# Gera/atualiza o arquivo mantendo cursor e fonte se existirem previamente
current_cursor="$CURSOR_NAME"
current_font="$GTK_FONT"
if [[ -f "$XSD_CONF" ]]; then
  # tenta extrair valores existentes
  cur=$(grep -E '^Gtk/CursorThemeName\s+".*"' "$XSD_CONF" | sed -E 's/^Gtk\/CursorThemeName "(.*)"/\1/'); current_cursor=${cur:-$CURSOR_NAME}
  fnt=$(grep -E '^Gtk/FontName\s+".*"' "$XSD_CONF" | sed -E 's/^Gtk\/FontName "(.*)"/\1/'); current_font=${fnt:-$GTK_FONT}
fi
cat > "$XSD_CONF" <<EOF
Net/ThemeName "$THEME_NAME"
Net/IconThemeName "$ICON_NAME"
Gtk/CursorThemeName "$current_cursor"
Gtk/FontName "$current_font"
EOF
log::info "xsettingsd configurado com tema $THEME_NAME e ícones $ICON_NAME"

# Reinicia xsettingsd se em execução (efeito imediato)
if pgrep -x xsettingsd >/dev/null 2>&1; then
  pkill -HUP xsettingsd || true
  log::info "Sinal enviado ao xsettingsd para recarregar configurações"
fi

# Atualiza GTK 3 settings (~/.config/gtk-3.0/settings.ini)
GTK3_DIR="$HOME/.config/gtk-3.0"
GTK3_INI="$GTK3_DIR/settings.ini"
mkdir -p -- "$GTK3_DIR"
if [[ -f "$GTK3_INI" ]]; then
  # edita em-place
  sed -i -E "s|^gtk-theme-name=.*$|gtk-theme-name=$THEME_NAME|" "$GTK3_INI" || true
  if grep -q '^gtk-icon-theme-name=' "$GTK3_INI"; then
    sed -i -E "s|^gtk-icon-theme-name=.*$|gtk-icon-theme-name=$ICON_NAME|" "$GTK3_INI"
  else
    echo "gtk-icon-theme-name=$ICON_NAME" >> "$GTK3_INI"
  fi
  # opcionalmente mantém fonte/cursor atuais
else
  cat > "$GTK3_INI" <<EOF
[Settings]
gtk-theme-name=$THEME_NAME
gtk-icon-theme-name=$ICON_NAME
gtk-font-name=$GTK_FONT
gtk-cursor-theme-name=$CURSOR_NAME
gtk-application-prefer-dark-theme=0
EOF
fi
log::info "GTK 3 configurado com tema $THEME_NAME e ícones $ICON_NAME"

# Executa pywal se disponível, priorizando o "landscape.jpg" como padrão
if ! command -v wal >/dev/null 2>&1; then
  log::warn "pywal (wal) não encontrado; pulando aplicação de paleta."
else
  if [[ -f "$WALL_DIR/landscape.jpg" ]]; then
    wal -i "$WALL_DIR/landscape.jpg" || true
    log::info "pywal executado com landscape.jpg"
  elif compgen -G "$WALL_DIR/*" >/dev/null; then
    # fallback: usa o arquivo mais recente do diretório
    latest_wall=$(ls -1t "$WALL_DIR" | head -n1)
    wal -i "$WALL_DIR/$latest_wall" || true
    log::info "pywal executado com $latest_wall (fallback)"
  else
    log::warn "Nenhum papel de parede encontrado em $WALL_DIR. pywal não foi executado."
  fi
fi

log::success "Tema aplicado: $THEME_NAME + $ICON_NAME"