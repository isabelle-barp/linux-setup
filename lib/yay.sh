# lib/yay.sh
# Funções relacionadas ao AUR usando yay

# Instala o yay (AUR helper)
install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  # Garante dependências de compilação
  if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman não encontrado. Este script é para Arch Linux." >&2
    return 1
  fi

  # Usa pacq se existir; caso contrário, usa pacman diretamente
  if command -v pacq >/dev/null 2>&1; then
    pacq -S --needed base-devel git
  else
    sudo pacman --noconfirm -S --needed base-devel git
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap "rm -rf '$tmp_dir'" EXIT

  cd "$tmp_dir"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd - >/dev/null
}

# Instala pacotes via yay (AUR)
aur_install() {
  # Garante yay
  if ! command -v yay >/dev/null 2>&1; then
    install_yay
  fi

  # Mostrar progresso para evitar a impressão de travamento e manter não interativo
  yay --noconfirm --sudoloop "$@"
}

# Verifica se pacote existe no AUR
is_aur_package() {
  local package="$1"
  if ! command -v yay >/dev/null 2>&1; then
    install_yay
  fi
  yay -Si "$package" >/dev/null 2>&1
}
