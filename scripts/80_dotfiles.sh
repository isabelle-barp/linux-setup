#!/usr/bin/env bash
# Aplica dotfiles com GNU Stow sem usar barras nos nomes de pacote.
# Uso:
#   bash scripts/80_dotfiles.sh                 # autodetecta pacotes em dotfiles/
#   bash scripts/80_dotfiles.sh zsh git         # aplica só alguns pacotes
# Variáveis de ambiente:
#   STOW_ADOPT=1        -> usa --adopt (move arquivos existentes para o repo)
#   DOTFILES_REPLACE=0  -> desativa substituição automática (por padrão substitui arquivos existentes)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"
STOW_DIR="$ROOT_DIR/dotfiles"

pacq -Sy
pacq -S --needed stow

# Lista de pacotes (subpastas de dotfiles/)
if (( "$#" > 0 )); then
  PKGS=("$@")
else
  mapfile -t PKGS < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
fi

if (( "${#PKGS[@]}" == 0 )); then
  echo "[WARN] Nenhum pacote em $STOW_DIR"; exit 0
fi

# Modo de substituição opcional: remove arquivos de destino existentes (somente arquivos/symlinks)
if [[ "${DOTFILES_REPLACE:-1}" == "1" ]]; then
  echo "[INFO] Substituição automática habilitada (DOTFILES_REPLACE=1). Removendo arquivos existentes no destino antes do stow."
  for pkg in "${PKGS[@]}"; do
    pkg_dir="$STOW_DIR/$pkg"
    if [[ ! -d "$pkg_dir" ]]; then
      echo "[WARN] Pacote inexistente: $pkg" >&2
      continue
    fi
    # Remove apenas arquivos e symlinks correspondentes
    while IFS= read -r -d '' src; do
      rel_path="${src#"$pkg_dir/"}"
      target="$HOME/$rel_path"
      if [[ -L "$target" || -f "$target" ]]; then
        echo "[RM] $target"
        rm -f -- "$target"
      fi
    done < <(find "$pkg_dir" \( -type f -o -type l \) -print0)
  done
else
  echo "[INFO] Substituição automática desabilitada (DOTFILES_REPLACE=0). Arquivos existentes serão mantidos."
fi

FLAGS=(-d "$STOW_DIR" -t "$HOME" -v -R)
if [[ "${STOW_ADOPT:-0}" == "1" ]]; then FLAGS+=("--adopt"); fi

echo "Aplicando pacotes: ${PKGS[*]}"
stow "${FLAGS[@]}" "${PKGS[@]}"

# Trata symlinks absolutos no repositório que o stow ignora: cria links equivalentes no HOME
for pkg in "${PKGS[@]}"; do
  pkg_dir="$STOW_DIR/$pkg"
  [[ -d "$pkg_dir" ]] || continue
  while IFS= read -r -d '' src; do
    link_target="$(readlink "$src" || true)"
    [[ -n "$link_target" ]] || continue
    # apenas alvos absolutos
    if [[ "$link_target" == /* ]]; then
      rel_path="${src#"$pkg_dir/"}"
      target="$HOME/$rel_path"
      mkdir -p -- "$(dirname -- "$target")"
      if [[ -e "$target" || -L "$target" ]]; then
        if [[ "${DOTFILES_REPLACE:-1}" == "1" ]]; then
          echo "[RM] $target"
          rm -f -- "$target"
        else
          echo "[WARN] Ignorando symlink absoluto (mantendo existente, DOTFILES_REPLACE=0): $target"
          continue
        fi
      fi
      ln -s -- "$link_target" "$target"
      echo "LINK: ${rel_path} => ${link_target}"
    fi
  done < <(find "$pkg_dir" -type l -print0)
done

echo "✓ Dotfiles aplicados."