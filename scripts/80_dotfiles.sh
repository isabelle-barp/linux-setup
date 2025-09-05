#!/usr/bin/env bash
# Aplica dotfiles com GNU Stow sem usar barras nos nomes de pacote.
# Uso:
#   bash scripts/80_dotfiles.sh           # autodetecta pacotes em dotfiles/
#   bash scripts/80_dotfiles.sh zsh git   # aplica só alguns pacotes
# Variáveis:
#   STOW_ADOPT=1   -> usa --adopt (move arquivos existentes para o repo)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"
STOW_DIR="$ROOT_DIR/dotfiles"

pacq -Sy
smart_install stow

# Lista de pacotes (subpastas de dotfiles/)
if (( "$#" > 0 )); then
  PKGS=("$@")
else
  mapfile -t PKGS < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
fi

if (( "${#PKGS[@]}" == 0 )); then
  echo "[WARN] Nenhum pacote em $STOW_DIR"; exit 0
fi

FLAGS=(-d "$STOW_DIR" -t "$HOME" -v -R)
if [[ "${STOW_ADOPT:-0}" == "1" ]]; then FLAGS+=("--adopt"); fi

echo "Aplicando pacotes: ${PKGS[*]}"
stow "${FLAGS[@]}" "${PKGS[@]}"

echo "✓ Dotfiles aplicados."