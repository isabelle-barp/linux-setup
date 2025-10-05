# lib/pacman_official.sh
# Funções para repositórios oficiais (pacman)

# Wrapper do pacman (similar ao aptq)
pacq() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    sudo pacman --noconfirm "$@"
  else
    sudo pacman --noconfirm --quiet "$@"
  fi
}

# Verifica se o pacote existe nos repositórios oficiais
is_official_package() {
  local package="$1"
  pacman -Si "$package" >/dev/null 2>&1
}
