#!/usr/bin/env bash
# Instala e configura o Starship (prompt) no ElementaryOS/Ubuntu-like
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
source "$ROOT_DIR/lib/apt.sh"

log::section "Instalando/ativando Starship"

# Dependências básicas
aptq update
aptq install curl ca-certificates || true

# Garante ~/.local/bin no PATH em próximos logins
mkdir -p "$HOME/.local/bin" "$HOME/.config"
grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"

# Instala Starship se necessário
if ! command -v starship >/dev/null 2>&1; then
  log::info "Baixando e instalando Starship (script oficial)"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
else
  log::info "Starship já instalado em: $(command -v starship)"
fi

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

log::success "Starship pronto! Abra um novo terminal (ou rode: exec zsh / exec bash)."
