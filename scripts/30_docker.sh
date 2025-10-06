#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"
source "$ROOT_DIR/lib/yay.sh"

log::section "Instalando e configurando Docker"

# 1) Instalação do Docker
if ! command -v docker >/dev/null 2>&1; then
  log::info "Docker não encontrado, instalando..."
  if is_official_package docker; then
    pacq -S --needed docker
  elif is_aur_package docker; then
    aur_install -S --needed docker
  else
    log::error "Pacote 'docker' não encontrado nos repositórios oficiais nem no AUR"
    exit 1
  fi
else
  log::info "Docker já está instalado"
fi

# Verifica se instalou corretamente
if ! command -v docker >/dev/null 2>&1; then
  log::error "Falha ao instalar docker"
  exit 1
fi

# 2) Habilitar e iniciar serviços do Docker
log::section "Habilitando serviços do Docker"
if systemctl is-enabled docker.service >/dev/null 2>&1; then
  log::info "docker.service já está habilitado"
else
  sudo systemctl enable docker.service
  log::success "docker.service habilitado"
fi

if systemctl is-enabled docker.socket >/dev/null 2>&1; then
  log::info "docker.socket já está habilitado"
else
  sudo systemctl enable docker.socket
  log::success "docker.socket habilitado"
fi

# Iniciar imediatamente
if systemctl is-active docker.service >/dev/null 2>&1; then
  log::info "docker.service já está ativo"
else
  sudo systemctl start docker.service || true
  log::info "docker.service iniciado"
fi

# 3) Criar grupo docker e adicionar usuário
log::section "Configurando permissões (grupo docker)"
if ! getent group docker >/dev/null 2>&1; then
  sudo groupadd docker
  log::success "Grupo 'docker' criado"
else
  log::info "Grupo 'docker' já existe"
fi

added_group=0
if id -nG "$USER" | grep -qw docker; then
  log::info "Usuário '$USER' já está no grupo docker"
else
  sudo usermod -aG docker "$USER"
  added_group=1
  log::success "Usuário '$USER' adicionado ao grupo docker"
fi

# 4) (Opcional) docker-compose
if ! command -v docker-compose >/dev/null 2>&1; then
  log::section "Instalando docker-compose (opcional)"
  if is_official_package docker-compose; then
    pacq -S --needed docker-compose || true
  elif is_aur_package docker-compose; then
    aur_install -S --needed docker-compose || true
  else
    log::warn "'docker-compose' não encontrado em repositórios oficiais nem no AUR — ignorando"
  fi
else
  log::info "docker-compose já está instalado"
fi

# 5) Mensagens finais
log::section "Finalizado"
log::success "Docker instalado e configurado"
if (( added_group == 1 )); then
  log::warn "Você precisa sair e entrar novamente (ou reiniciar) para aplicar as permissões do grupo docker."
fi

log::info "Teste rápido: docker run --rm hello-world"