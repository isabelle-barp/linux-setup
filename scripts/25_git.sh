#!/usr/bin/env bash
# Configurações globais do Git
# - Define o editor padrão como vim
# - Sempre configura upstream automaticamente no primeiro push
# - Usa rebase por padrão ao fazer pull

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/utils.sh"

log::section "Configurando Git (global)"

# Garante que o git esteja instalado (em Arch, pacote 'git')
utils::need_cmd git git

# Editor padrão
log::info "Definindo editor padrão: vim"
git config --global core.editor "vim"

# Branch inicial padrão: 'main' (em vez de 'master')
log::info "Definindo branch inicial padrão para 'main'"
git config --global init.defaultBranch main

# Push: usar sempre o upstream; e configurar upstream automaticamente no primeiro push
# push.default=upstream faz 'git push' enviar para o ramo de upstream
# push.autoSetupRemote=true (Git >= 2.37) configura o remote/upstream automaticamente no primeiro push
log::info "Configurando push para usar branch upstream e criar upstream automaticamente no primeiro push"
git config --global push.default upstream
git config --global push.autoSetupRemote true

# Pull: rebase por padrão; e autostash para facilitar
log::info "Habilitando rebase por padrão no git pull (com autostash)"
git config --global pull.rebase true
git config --global rebase.autostash true

# Resumo
log::success "Git configurado. Itens principais:"
(git config --global -l | grep -E '^(core.editor|init.defaultBranch|push.default|push.autoSetupRemote|pull.rebase|rebase.autostash)=') || true
