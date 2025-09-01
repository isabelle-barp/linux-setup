#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.local/share/fonts"
# Exemplo: FiraCode
curl -L -o /tmp/FiraCode.zip https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
unzip -o /tmp/FiraCode.zip -d /tmp/FiraCode
cp -r /tmp/FiraCode/ttf/*.ttf "$HOME/.local/share/fonts/"
fc-cache -f
