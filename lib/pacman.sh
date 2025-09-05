# lib/pacman.sh

# Pacman wrapper function similar to aptq()
pacq() {
  # Se DEBUG=1, não silencia
  if [[ "${DEBUG:-0}" == "1" ]]; then
    sudo pacman --noconfirm "$@"
  else
    sudo pacman --noconfirm --quiet "$@"
  fi
}

# AUR helper functions
aur_install() {
  local packages=("$@")
  
  # Check if yay is available, install if not
  if ! command -v yay >/dev/null 2>&1; then
    install_yay
  fi
  
  # Install packages via yay
  if [[ "${DEBUG:-0}" == "1" ]]; then
    yay --noconfirm "$@"
  else
    yay --noconfirm --quiet "$@" 2>/dev/null
  fi
}

# Install yay AUR helper
install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi
  
  # Install base-devel if not present
  pacq -S --needed base-devel git
  
  # Create temp directory for yay installation
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap "rm -rf '$tmp_dir'" EXIT
  
  # Clone and build yay
  cd "$tmp_dir"
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  
  cd - >/dev/null
}

# Check if package is available in official repos
is_official_package() {
  local package="$1"
  pacman -Si "$package" >/dev/null 2>&1
}

# Check if package is available in AUR
is_aur_package() {
  local package="$1"
  if command -v yay >/dev/null 2>&1; then
    yay -Si "$package" >/dev/null 2>&1
  else
    # Fallback: try to check AUR via web API
    curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]=$package" | grep -q '"resultcount":1'
  fi
}

# Smart package installation - tries official repos first, then AUR
smart_install() {
  local packages=("$@")
  local official_packages=()
  local aur_packages=()
  
  # Separate official and AUR packages
  for package in "${packages[@]}"; do
    if is_official_package "$package"; then
      official_packages+=("$package")
    elif is_aur_package "$package"; then
      aur_packages+=("$package")
    else
      echo "Warning: Package '$package' not found in official repos or AUR" >&2
    fi
  done
  
  # Install official packages first
  if [[ ${#official_packages[@]} -gt 0 ]]; then
    pacq -S "${official_packages[@]}"
  fi
  
  # Install AUR packages
  if [[ ${#aur_packages[@]} -gt 0 ]]; then
    aur_install -S "${aur_packages[@]}"
  fi
}