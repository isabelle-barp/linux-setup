#!/usr/bin/env bash
# Mapeia ⌘ (Super) + C/V/A/Z/X -> Ctrl+C/V/A/Z/X globalmente (Xorg) usando xbindkeys + xdotool
# Detecta Alt↔Super (altwin:swap_alt_win) e usa o modificador correto (Mod1=Alt, Mod4=Super).
# Uso: bash scripts/63_cmd_shortcuts.sh [apply|undo|status]
# Obs: Em Wayland, xbindkeys/xdotool não funcionam. O script avisa e sai sem erro.

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

OPT="${1:-apply}"
XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-}"

# --- paths/logger do seu repo ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

# Arquivos geridos
XBRC="$HOME/.xbindkeysrc"                  # config principal do xbindkeys
MARK_BEGIN="# >>> cmd-shortcuts (managed)"
MARK_END="# <<< cmd-shortcuts (managed)"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART="$AUTOSTART_DIR/xbindkeys.desktop"

have(){ command -v "$1" >/dev/null 2>&1; }

detect_swap(){
  # 1) GNOME settings (Wayland/Xorg)
  if have gsettings; then
    if gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null | grep -q "altwin:swap_alt_win"; then
      return 0
    fi
  fi
  # 2) Sessão Xorg atual
  if have setxkbmap && setxkbmap -query 2>/dev/null | grep -q "altwin:swap_alt_win"; then
    return 0
  fi
  # 3) Sistema
  if grep -q "altwin:swap_alt_win" /etc/default/keyboard 2>/dev/null; then
    return 0
  fi
  return 1
}

mod_for_cmd(){
  if detect_swap; then echo "Mod1"; else echo "Mod4"; fi
}

ensure_autostart(){
  mkdir -p "$AUTOSTART_DIR"
  if [[ ! -f "$AUTOSTART" ]]; then
    cat > "$AUTOSTART" <<EOF
[Desktop Entry]
Type=Application
Name=xbindkeys
Exec=xbindkeys
X-GNOME-Autostart-enabled=true
NoDisplay=false
EOF
  fi
}

apply_xorg(){
  log::section "Configurando ⌘-atalhos via xbindkeys (Xorg)"

  # Dependências
  sudo apt-get update -y
  sudo apt-get install -y xbindkeys xdotool || true

  local MOD; MOD="$(mod_for_cmd)"
  log::info "Tecla física ⌘ mapeada como: $MOD (swap Alt↔Super: $(detect_swap && echo on || echo off))"

  # Bloco de config gerenciado (idempotente)
  local TMP; TMP="$(mktemp)"
  # remove bloco anterior se existir
  if [[ -f "$XBRC" ]] && grep -qF "$MARK_BEGIN" "$XBRC"; then
    awk -v s="$MARK_BEGIN" -v e="$MARK_END" '
      $0==s {skip=1; next} $0==e {skip=0; next} !skip {print}
    ' "$XBRC" > "$TMP"
    mv "$TMP" "$XBRC"
  fi

  # adiciona bloco novo
  {
    echo "$MARK_BEGIN"
    echo "# Super/Command+<key> -> Ctrl+<key>  (usa $MOD como modificador)"
    echo "# cópia"
    echo "\"xdotool key --clearmodifiers ctrl+c\""
    echo "  $MOD + c"
    echo "# colar"
    echo "\"xdotool key --clearmodifiers ctrl+v\""
    echo "  $MOD + v"
    echo "# selecionar tudo"
    echo "\"xdotool key --clearmodifiers ctrl+a\""
    echo "  $MOD + a"
    echo "# recortar"
    echo "\"xdotool key --clearmodifiers ctrl+x\""
    echo "  $MOD + x"
    echo "# desfazer"
    echo "\"xdotool key --clearmodifiers ctrl+z\""
    echo "  $MOD + z"
    echo "$MARK_END"
  } >> "$XBRC"

  ensure_autostart

  # (Re)inicia xbindkeys
  if pgrep -x xbindkeys >/dev/null 2>&1; then
    killall -HUP xbindkeys || true
  else
    nohup xbindkeys >/dev/null 2>&1 &
  fi

  log::success "Atalhos prontos! Teste ⌘+C/⌘+V/⌘+A etc. (em apps X11)."
}

apply(){
  # Wayland não permite sintetizar teclas com xdotool/xbindkeys
  if [[ "${XDG_SESSION_TYPE,,}" == "wayland" ]]; then
    log::warn "Sessão Wayland detectada. xbindkeys/xdotool não funcionam no Wayland."
    log::warn "Opções: usar Xorg; ou ferramentas de baixo nível (ex.: keyd/xremap) com uinput."
    log::warn "Como alternativa temporária, você pode continuar usando Ctrl+C/V/A normalmente."
    return 0
  fi
  apply_xorg
}

undo(){
  log::section "Removendo mapeamentos ⌘-atalhos (Xorg)"
  if [[ -f "$XBRC" ]] && grep -qF "$MARK_BEGIN" "$XBRC"; then
    awk -v s="$MARK_BEGIN" -v e="$MARK_END" '
      $0==s {skip=1; next} $0==e {skip=0; next} !skip {print}
    ' "$XBRC" > "$XBRC.tmp" && mv "$XBRC.tmp" "$XBRC"
    log::info "Bloco removido de $XBRC"
  else
    log::info "Nada para remover em $XBRC"
  fi
  # não apagamos o autostart (pode haver outras configs);
  # se quiser, desative xbindkeys no app de inicialização.
  if pgrep -x xbindkeys >/dev/null 2>&1; then
    killall -HUP xbindkeys || true
  fi
  log::success "Remoção concluída."
}

status(){
  echo "Sessão:          ${XDG_SESSION_TYPE:-desconhecida}"
  echo "Swap Alt↔Super:  $(detect_swap && echo on || echo off)"
  echo "Modificador ⌘:   $(mod_for_cmd)"
  echo "xbindkeys rc:    $([[ -f "$XBRC" ]] && echo 'existe' || echo 'não existe')"
  if [[ -f "$XBRC" ]]; then
    awk "/$MARK_BEGIN/{flag=1;print;next}/$MARK_END/{print;flag=0}flag" "$XBRC" || true
  fi
}

case "${OPT}" in
  apply)  apply ;;
  undo)   undo ;;
  status) status ;;
  *) echo "Uso: $0 [apply|undo|status]"; exit 2 ;;
esac
