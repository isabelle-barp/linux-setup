#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"

log::section "Instalando e configurando Bluetooth"

# 1) Instalar pacotes necessários (bluez, bluez-utils)
need_install=()
for pkg in bluez bluez-utils; do
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    log::info "Pacote '$pkg' já está instalado"
  else
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      need_install+=("$pkg")
    else
      log::warn "Pacote '$pkg' não encontrado nos repositórios oficiais — ignorando"
    fi
  fi
done

if (( ${#need_install[@]} > 0 )); then
  log::info "Instalando: ${need_install[*]}"
  pacq -S --needed "${need_install[@]}"
fi

# 2) Habilitar e iniciar o serviço bluetooth
service=bluetooth.service

if systemctl is-enabled "$service" >/dev/null 2>&1; then
  log::info "$service já está habilitado"
else
  sudo systemctl enable "$service"
  log::success "$service habilitado"
fi

if systemctl is-active "$service" >/dev/null 2>&1; then
  log::info "$service já está ativo"
else
  # Em algumas distros/ambientes pode falhar se o hardware não estiver presente; não falhe o script por isso
  if sudo systemctl start "$service"; then
    log::success "$service iniciado"
  else
    log::warn "Não foi possível iniciar $service agora (pode não haver hardware). Prosseguindo."
  fi
fi

log::success "Bluetooth configurado" 
