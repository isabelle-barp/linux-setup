#!/usr/bin/env bash
# Atalho para abrir o menu de aplicativos do elementary com ⌘+Espaço,
# respeitando swap Alt↔Super. Usa gsettings e um wrapper para o Wingpanel.
# Uso: bash scripts/62_open_apps_shortcut.sh [apply|undo|status]
# Vars: BINDING="<Super>space" (sobrepõe auto-detecção)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

OPT="${1:-apply}"

# --- paths e logger do seu repo ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

WRAP="$HOME/.local/bin/open-apps-menu"
PATH_KEY="org.gnome.settings-daemon.plugins.media-keys"
BASE="/org/gnome/settings-daemon/plugins/media-keys"
ITEM="$BASE/custom-keybindings/custom-open-apps/"
ITEM_KEY="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ITEM"

have() { command -v "$1" >/dev/null 2>&1; }

detect_swap() {
  # 1) gsettings
  if have gsettings; then
    if gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null | grep -q "altwin:swap_alt_win"; then
      return 0
    fi
  fi
  # 2) sessão atual (Xorg)
  if have setxkbmap && setxkbmap -query 2>/dev/null | grep -q "altwin:swap_alt_win"; then
    return 0
  fi
  # 3) sistema
  if grep -q "altwin:swap_alt_win" /etc/default/keyboard 2>/dev/null; then
    return 0
  fi
  return 1
}

effective_binding() {
  if [[ -n "${BINDING:-}" ]]; then
    echo "$BINDING"; return
  fi
  if detect_swap; then
    echo "<Alt>space"   # tecla física ⌘ virou Alt
  else
    echo "<Super>space" # tecla física ⌘ é Super
  fi
}

make_wrapper() {
  mkdir -p "$(dirname "$WRAP")"
  cat > "$WRAP" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
try_wingpanel() {
  local bin="$1"
  "$bin" --toggle-indicator=app-launcher         2>/dev/null && exit 0 || true
  "$bin" --toggle-indicator app-launcher         2>/dev/null && exit 0 || true
  "$bin" --toggle-indicator=applications-menu    2>/dev/null && exit 0 || true
  "$bin" --toggle-indicator applications-menu    2>/dev/null && exit 0 || true
  return 1
}
if command -v io.elementary.wingpanel >/dev/null 2>&1; then
  try_wingpanel io.elementary.wingpanel || exit 1
elif command -v wingpanel >/dev/null 2>&1; then
  try_wingpanel wingpanel || exit 1
else
  exit 1
fi
SH
  chmod +x "$WRAP"
  grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
}

free_conflicts() {
  local bind="$1"
  if [[ "$bind" == "<Super>space" ]]; then
    # Super+Space costuma trocar layout de teclado → libera
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]" || true
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]" || true
  fi
  if [[ "$bind" == "<Alt>space" ]]; then
    # Alt+Space normalmente abre o menu da janela → libera
    gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]" || true
  fi
}

add_path() {
  local cur
  cur="$(gsettings get "$PATH_KEY" custom-keybindings)"
  if [[ "$cur" == "@as []" || "$cur" == "[]" ]]; then
    gsettings set "$PATH_KEY" custom-keybindings "['$ITEM']"
  elif [[ "$cur" != *"$ITEM"* ]]; then
    gsettings set "$PATH_KEY" custom-keybindings "${cur%]*}, '$ITEM']"
  fi
}

remove_path() {
  local cur new
  cur="$(gsettings get "$PATH_KEY" custom-keybindings 2>/dev/null || echo "[]")"
  new="$cur"
  new="${new//, '$ITEM'/}"
  new="${new//'$ITEM', /}"
  new="${new//'$ITEM'/}"
  [[ "$new" =~ \[.*\] ]] || new="[]"
  gsettings set "$PATH_KEY" custom-keybindings "$new"
}

apply() {
  local bind; bind="$(effective_binding)"
  log::section "Criando wrapper e atalho ($bind → Applications)"
  make_wrapper
  free_conflicts "$bind"

  gsettings set "$ITEM_KEY" name 'Open Applications'
  gsettings set "$ITEM_KEY" command "$WRAP"
  gsettings set "$ITEM_KEY" binding "$bind"
  add_path

  if detect_swap; then
    log::info "Detectado swap Alt↔Super ativo → usando $bind (tecla física ⌘)."
  else
    log::info "Sem swap Alt↔Super → usando $bind."
  fi
  log::success "Atalho criado!"
}

undo() {
  log::section "Removendo atalho customizado"
  gsettings reset "$ITEM_KEY" name || true
  gsettings reset "$ITEM_KEY" command || true
  gsettings reset "$ITEM_KEY" binding || true
  remove_path
  log::success "Atalho removido (teclas de sistema não foram reconfiguradas)."
}

status() {
  echo "Swap Alt↔Super detectado? $([[ detect_swap ]] && echo sim || echo não)"
  echo "Binding efetivo (se aplicar agora): $(effective_binding)"
  echo "Wrapper:        $([[ -x "$WRAP" ]] && echo 'OK' || echo 'faltando')  ($WRAP)"
  echo "Binding atual:  $(gsettings get "$ITEM_KEY" binding 2>/dev/null || echo 'n/d')"
  echo "Comando:        $(gsettings get "$ITEM_KEY" command 2>/dev/null || echo 'n/d')"
  echo "Na lista:       $(gsettings get "$PATH_KEY" custom-keybindings 2>/dev/null || echo 'n/d')"
}

case "$OPT" in
  apply)  apply ;;
  undo)   undo ;;
  status) status ;;
  *) echo "Uso: $0 [apply|undo|status]  (BINDING='<Alt>space' ou '<Super>space' p/ forçar)"; exit 2 ;;
esac
