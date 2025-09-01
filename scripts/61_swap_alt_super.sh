#!/usr/bin/env bash
# Troca Alt ↔ Super (Command) no ElementaryOS (Pantheon)
# - Aplica agora (setxkbmap)
# - Persiste em Xorg/console (/etc/default/keyboard)
# - Persiste em Wayland/Pantheon (gsettings)
# Uso: bash scripts/61_swap_alt_super.sh [apply|undo|status]
# DEBUG=1 para modo verboso

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x

# Reexecuta em bash se rodaram com sh/dash
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi

# Trap de erro amigável
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: falhou comando: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths robustos
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Logger obrigatório
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

OPT="${1:-apply}"   # apply | undo | status
OPTION="altwin:swap_alt_win"
KB_FILE="/etc/default/keyboard"

# helpers básicos
msg(){ log::section "$*"; }
ok(){  log::success "$*"; }
err(){ log::error "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# ---- /etc/default/keyboard helpers ----
kb_get(){ grep -E '^XKBOPTIONS=' "$KB_FILE" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' || true; }
kb_set(){
  local new="$1"
  sudo install -m 644 -D "$KB_FILE" "$KB_FILE" 2>/dev/null || true
  sudo cp "$KB_FILE" "${KB_FILE}.bak.$(date +%Y%m%d%H%M%S)" || true
  if grep -qE '^XKBOPTIONS=' "$KB_FILE"; then
    sudo sed -i -E "s|^XKBOPTIONS=.*$|XKBOPTIONS=\"$new\"|" "$KB_FILE"
  else
    echo "XKBOPTIONS=\"$new\"" | sudo tee -a "$KB_FILE" >/dev/null
  fi
  # aplica sem reboot
  sudo dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1 || true
  sudo udevadm trigger --subsystem-match=input --action=change 2>/dev/null || true
  sudo systemctl restart keyboard-setup 2>/dev/null || true
}

# ---- gsettings helpers (Wayland/Pantheon) ----
gs_get(){ gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null || echo "@as []"; }
gs_set(){ gsettings set org.gnome.desktop.input-sources xkb-options "$1" 2>/dev/null || true; }
gs_add_option(){
  local cur; cur="$(gs_get)"
  if [[ "$cur" == "@as []" || "$cur" == "[]" ]]; then
    gs_set "['$OPTION']"
  elif grep -q "$OPTION" <<<"$cur"; then
    : # já tem
  else
    gs_set "${cur%]*}, '$OPTION']"
  fi
}
gs_remove_option(){
  local cur new; cur="$(gs_get)"
  new="$(sed "s/'$OPTION'//; s/, ,/,/; s/\[, /[/; s/, \]/]/" <<<"$cur")"
  gs_set "$new"
}

apply_now(){
  if have setxkbmap; then
    msg "Aplicando agora na sessão (setxkbmap)…"
    setxkbmap -option "$OPTION" || true
    ok  "Aplicado (se algo não refletir em apps, relogue a sessão)."
  else
    msg "setxkbmap indisponível nesta sessão; seguindo apenas com persistência."
  fi
}

apply_persist(){
  msg "Persistindo em Xorg/console (/etc/default/keyboard)…"
  local cur new; cur="$(kb_get || true)"
  if   [[ -z "$cur" ]]; then new="$OPTION"
  elif grep -q "$OPTION" <<<"$cur"; then new="$cur"
  else new="${cur%,},$OPTION"; fi
  kb_set "$new"
  ok  "XKBOPTIONS=\"$new\""

  if have gsettings; then
    msg "Persistindo em Wayland/Pantheon (gsettings)…"
    gs_add_option
    ok  "xkb-options: $(gs_get)"
  fi
}

undo_all(){
  msg "Removendo swap Alt↔Super…"
  local cur new; cur="$(kb_get || true)"
  if [[ -n "$cur" ]]; then
    new="$(sed "s/$OPTION//; s/,,/,/; s/^,//; s/,$//" <<<"$cur")"
    kb_set "$new"
    ok "XKBOPTIONS=\"$new\""
  fi
  if have gsettings; then
    gs_remove_option
    ok "Wayland/Pantheon: $(gs_get)"
  fi
  if have setxkbmap; then setxkbmap -option; fi
}

status(){
  echo "---- STATUS ----"
  echo "Sessão atual:"
  have setxkbmap && setxkbmap -query | sed 's/^/  /' || echo "  setxkbmap indisponível"
  echo "Persistência Xorg/console (/etc/default/keyboard):"
  if [[ -r "$KB_FILE" ]]; then
    grep -E '^(XKBMODEL|XKBLAYOUT|XKBVARIANT|XKBOPTIONS)=' "$KB_FILE" | sed 's/^/  /'
  else
    echo "  $KB_FILE não encontrado"
  fi
  echo "Wayland/Pantheon (gsettings):"
  if have gsettings; then
    echo "  $(gs_get)"
  else
    echo "  gsettings indisponível"
  fi
}

case "${OPT}" in
  apply)  apply_now; apply_persist;;
  undo)   undo_all;;
  status) status;;
  *)      echo "Uso: $0 [apply|undo|status]"; exit 2;;
esac

ok "Concluído."
