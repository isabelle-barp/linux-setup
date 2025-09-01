#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"


log::section "APT update/upgrade"
sudo apt-get update -y
sudo apt-get upgrade -y


log::section "Instalando pacotes APT"
mapfile -t packages < <(grep -vE '^#|^$' "$ROOT_DIR/config/apt-packages.txt")
if ((${#packages[@]})); then
  sudo apt-get install -y "${packages[@]}"
fi