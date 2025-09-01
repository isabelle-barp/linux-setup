#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"


log::section "APT update/upgrade"
aptq update
aptq upgrade


log::section "Instalando pacotes APT"
mapfile -t packages < <(grep -vE '^#|^$' "$ROOT_DIR/config/apt-packages.txt")
if ((${#packages[@]})); then
  aptq install "${packages[@]}"
fi