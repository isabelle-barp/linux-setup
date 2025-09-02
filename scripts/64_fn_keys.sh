#!/usr/bin/env bash
# Define o comportamento das teclas de função via hid_apple (padrão: F1–F12)
# Uso: bash scripts/64_fn_keys.sh [1|2|3]
# 1 = mídias por padrão (Fn -> F1–F12)
# 2 = F1–F12 por padrão (Fn -> mídias)  <-- recomendado
# 3 = auto

set -euo pipefail

MODE="${1:-2}"                            # default: 2 (F1–F12)
CONF="/etc/modprobe.d/hid_apple.conf"

echo "→ Gravando persistência em $CONF (fnmode=$MODE)…"
echo "options hid_apple fnmode=$MODE" | sudo tee "$CONF" >/dev/null
echo "→ Atualizando initramfs…"
sudo update-initramfs -u

# Aplica agora (sem precisar reiniciar)
echo "→ Aplicando agora (recarregando módulo hid_apple, se carregado)…"
if lsmod | grep -q '^hid_apple'; then
  sudo modprobe -r hid_apple && sudo modprobe hid_apple || true
else
  # tenta carregar (se teclado Apple/compat usar hid_apple)
  sudo modprobe hid_apple || true
fi

CURRENT="$(cat /sys/module/hid_apple/parameters/fnmode 2>/dev/null || echo "desconhecido")"
echo "✓ fnmode atual: $CURRENT (1=mídia, 2=funções, 3=auto)"
echo "Pronto! Se algo não aplicar em todos os apps, reinicie quando quiser."
