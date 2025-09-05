#!/usr/bin/env bash
# Configura o Starship (prompt) no Arch Linux
# Uso:
#   bash scripts/59_starship.sh
# Variáveis opcionais:
#   STARSHIP_FORCE=1   # sobrescreve ~/.config/starship.toml
#   SHELLS="zsh bash"  # shells nos quais habilitar o starship (default: "zsh bash")

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths e logger do repo
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"

log::section "Configurando Starship"

# Garante ~/.config existe
mkdir -p "$HOME/.config"

# Verifica se Starship está instalado
if ! command -v starship >/dev/null 2>&1; then
  log::error "Starship não encontrado! Certifique-se que foi instalado via pacman."
  exit 1
fi

log::info "Starship encontrado em: $(command -v starship)"

# Habilita no(s) shell(s)
SHELLS="${SHELLS:-zsh bash}"
enable_in_rc() {
  local rc="$1" init_line='eval "$(starship init __SHELL__)"'
  local shell_name="$2"
  if [[ -f "$rc" ]]; then
    grep -q 'starship init' "$rc" || echo "${init_line/__SHELL__/$shell_name}" >> "$rc"
  else
    echo "${init_line/__SHELL__/$shell_name}" >> "$rc"
  fi
}

for sh in $SHELLS; do
  case "$sh" in
    zsh)  enable_in_rc "$HOME/.zshrc" zsh ;;
    bash) enable_in_rc "$HOME/.bashrc" bash ;;
  esac
done

log::success "Starship configurado! Abra um novo terminal (ou rode: exec zsh / exec bash)."
