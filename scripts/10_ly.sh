#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman_official.sh"
source "$ROOT_DIR/lib/yay.sh"


log::section "Configurando ly como gerenciador de login"

# Verificar se ly está instalado
if ! command -v ly >/dev/null 2>&1; then
    log::warn "ly não encontrado, instalando..."
    if is_official_package ly; then
        pacq -S --needed ly
    elif is_aur_package ly; then
        aur_install -S --needed ly
    else
        # Tentar pacote alternativo do AUR
        if is_aur_package ly-git; then
          aur_install -S --needed ly-git
        else
          log::error "Pacote 'ly' não encontrado em repositórios oficiais nem no AUR"
          exit 1
        fi
    fi
fi

# Verificar se ly foi instalado com sucesso
if ! command -v ly >/dev/null 2>&1; then
    log::error "Falha ao instalar ly"
    exit 1
fi

log::info "ly encontrado e instalado com sucesso"

# Configurar ly
log::section "Configurando ly"

# Criar diretório de configuração se não existir
sudo mkdir -p /etc/ly

# Configuração básica do ly (não sobrescreve se já existir)
if [[ ! -f /etc/ly/config.ini ]]; then
  log::info "Criando arquivo de configuração padrão do ly em /etc/ly/config.ini"
  sudo tee /etc/ly/config.ini > /dev/null << 'EOF'
# Configuração do ly
# Consulte `man ly` e /usr/share/doc/ly/config.example para mais opções

# Animação de entrada
animate = true

# Tecla de função para alternar TTY (opcional)
# tty = 2

# Permite salvar último usuário/sessão
save = true
save_file = /etc/ly/save

# Layout do teclado (ajuste conforme necessário)
# lang = pt

# Caminho para comandos de sessão personalizados
# xinitrc = /etc/ly/xinitrc
EOF
  log::success "Arquivo de configuração do ly criado"
else
  log::info "/etc/ly/config.ini já existe — mantendo configuração atual"
fi

# Desabilitar outros gerenciadores de display se existirem
log::section "Desabilitando outros gerenciadores de display"

display_managers=("gdm" "lightdm" "sddm" "xdm" "lxdm")
for dm in "${display_managers[@]}"; do
    if systemctl is-enabled "$dm" >/dev/null 2>&1; then
        log::info "Desabilitando $dm"
        sudo systemctl disable "$dm" >/dev/null 2>&1 || true
        sudo systemctl stop "$dm" >/dev/null 2>&1 || true
    fi
done

# Habilitar ly
log::section "Habilitando ly"
if systemctl is-enabled ly.service >/dev/null 2>&1; then
  log::info "ly.service já está habilitado"
else
  sudo systemctl enable ly.service
  log::success "ly habilitado com sucesso"
fi

# Verificar se awesome está instalado para compatibilidade
if command -v awesome >/dev/null 2>&1; then
    log::info "Awesome WM encontrado - compatibilidade verificada"
else
    log::warn "Awesome WM não encontrado. Certifique-se de instalá-lo para usar como ambiente de desktop."
fi

# Informações finais
log::section "Configuração concluída"
log::success "ly foi configurado como gerenciador de login"
log::info "Para usar o ly:"
log::info "  1. Reinicie o sistema ou execute: sudo systemctl start ly.service"
log::info "  2. Na tela de login, selecione sua sessão (Awesome WM estará disponível)"
log::info "  3. Digite seu usuário e senha"
log::info ""
log::info "Configurações adicionais podem ser feitas em: /etc/ly/config.ini"