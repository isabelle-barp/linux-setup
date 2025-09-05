#!/usr/bin/env bash
set -euo pipefail


utils::require_internet(){
if ! ping -c1 -W2 1.1.1.1 &>/dev/null; then
echo "Sem internet"; exit 1; fi
}


utils::require_distro(){
local id=${1:-}
if [[ -r /etc/os-release ]]; then
. /etc/os-release
[[ ${ID,,} == *"$id"* ]] && return 0
fi
return 1
}


utils::require_arch(){
if [[ -r /etc/os-release ]]; then . /etc/os-release; fi
[[ ${ID:-} == arch ]] || {
echo "Esta automação é para Arch Linux"; exit 1; }
}


utils::need_cmd(){ command -v "$1" >/dev/null 2>&1 || sudo pacman -Sy --noconfirm "$2"; }
