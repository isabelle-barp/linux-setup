#!/usr/bin/env bash
# Instala/atualiza Podman no ElementaryOS (Ubuntu-like)
# - Usa o repositório oficial do Ubuntu (sem Kubic)
# - Instalação idempotente
# Uso:
#   bash scripts/30_podman.sh
# Variáveis:
#   PODMAN_FORCE=1  # força reinstalar mesmo se já houver

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# ---- Paths e logger do seu repo ----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"

log::section "Instalando/atualizando Podman"

# ---- Idempotência: verificar se já está instalado ----
if command -v podman >/dev/null 2>&1 && [[ "${PODMAN_FORCE:-0}" != "1" ]]; then
  CURRENT_VERSION=$(podman --version 2>/dev/null || echo "versão desconhecida")
  log::success "Podman já instalado: $CURRENT_VERSION"
  exit 0
else
  log::info "Podman não encontrado ou PODMAN_FORCE=1, prosseguindo com instalação..."
fi

# ---- Pré-requisitos ----
log::info "Instalando pré-requisitos..."
aptq update
aptq install curl wget gnupg2 software-properties-common ca-certificates

# ---- Remover Kubic (se existir) e garantir repositórios oficiais ----
KEYRING_DIR="/etc/apt/keyrings"
sudo mkdir -p "$KEYRING_DIR"

if [[ -f /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list ]]; then
  log::info "Removendo repositório Kubic existente..."
  sudo rm -f /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list || true
fi
if [[ -f "$KEYRING_DIR/kubic-libcontainers.gpg" ]]; then
  log::info "Removendo chave Kubic existente..."
  sudo rm -f "$KEYRING_DIR/kubic-libcontainers.gpg" || true
fi

log::info "Garantindo que o repositório 'universe' esteja habilitado..."
sudo add-apt-repository -y universe >/dev/null 2>&1 || true

# ---- Atualizar lista de pacotes ----
log::info "Atualizando lista de pacotes..."
aptq update

# ---- Instalar Podman e podman-compose ----
log::info "Instalando Podman e podman-compose..."
aptq install podman podman-compose || {
  # Fallback: algumas distros não possuem pacote podman-compose; tenta via pipx
  log::warn "Pacote 'podman-compose' não disponível via apt. Tentando instalar via pipx..."
  # Instalar pipx e dependências mínimas
  aptq install pipx python3-pip python3-venv || true
  if command -v pipx >/dev/null 2>&1; then
    if ! pipx list 2>/dev/null | grep -q '^package podman-compose '; then
      pipx install podman-compose || log::error "Falha ao instalar podman-compose via pipx"
    fi
    # Garantir shims do pipx no PATH atual e persistir para novas sessões
    export PATH="$HOME/.local/bin:$PATH"
    pipx ensurepath >/dev/null 2>&1 || true
  else
    log::error "pipx não disponível e pacote apt de podman-compose ausente. Instale manualmente."
  fi
}

# ---- Verificar disponibilidade do podman-compose ----
if command -v podman-compose >/dev/null 2>&1; then
  log::success "podman-compose disponível: $(podman-compose --version 2>/dev/null || echo 'instalado')"
else
  if command -v pipx >/dev/null 2>&1 && pipx list 2>/dev/null | grep -q '^package podman-compose '; then
    log::warn "podman-compose instalado via pipx, mas não encontrado no PATH atual."
    log::info "Execute 'pipx ensurepath' e abra um novo terminal, ou adicione '$HOME/.local/bin' ao PATH."
  else
    log::error "podman-compose não foi instalado. Verifique os logs acima ou instale manualmente: 'sudo apt-get install podman-compose' ou 'pipx install podman-compose'"
  fi
fi

# ---- Configurações pós-instalação ----
log::info "Configurando Podman para uso sem root..."

# Verificar se subuid e subgid estão configurados
if ! grep -q "^${USER}:" /etc/subuid 2>/dev/null; then
  log::info "Configurando subuid para usuário $USER..."
  echo "${USER}:100000:65536" | sudo tee -a /etc/subuid >/dev/null
fi

if ! grep -q "^${USER}:" /etc/subgid 2>/dev/null; then
  log::info "Configurando subgid para usuário $USER..."
  echo "${USER}:100000:65536" | sudo tee -a /etc/subgid >/dev/null
fi

# ---- Habilitar e iniciar serviços (opcional para rootless) ----
if systemctl --user list-unit-files podman.socket >/dev/null 2>&1; then
  log::info "Habilitando socket do Podman para o usuário..."
  systemctl --user enable --now podman.socket 2>/dev/null || log::warn "Falha ao habilitar socket do Podman (não crítico)"
fi

# ---- Verificar instalação ----
if command -v podman >/dev/null 2>&1; then
  INSTALLED_VERSION=$(podman --version)
  log::success "Podman instalado com sucesso: $INSTALLED_VERSION"

  # Testar funcionamento básico
  log::info "Testando Podman..."
  if podman info >/dev/null 2>&1; then
    log::success "Podman funcionando corretamente"
  else
    log::warn "Podman instalado mas pode precisar de logout/login para funcionar completamente"
  fi

  log::info "Para usar Podman sem sudo, faça logout/login ou execute: newgrp podman"
  log::success "Pronto! Execute 'podman --help' para começar a usar."
else
  log::error "Falha na instalação do Podman"
  exit 1
fi