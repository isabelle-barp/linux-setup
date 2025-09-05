#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pacman.sh"


log::section "Configurando ly como gerenciador de login"

# Verificar se ly está instalado
if ! command -v ly >/dev/null 2>&1; then
    log::warn "ly não encontrado, instalando..."
    smart_install ly
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

# Configuração básica do ly
log::info "Criando arquivo de configuração do ly"
sudo tee /etc/ly/config.ini > /dev/null << 'EOF'
# Configuração do ly
# Animação de entrada
animate = true

# Tecla de função para alternar TTY (opcional)
# tty = 2

# Tempo limite para login automático (desabilitado)
# blank_password = true
# hide_borders = true

# Configurações de aparência
save = true
save_file = /etc/ly/save

# Layout do teclado (ajustar conforme necessário)
# Descomente e configure se necessário
# lang = pt

# Path para comandos de sessão personalizados
# xinitrc = /etc/ly/xinitrc
EOF

log::success "Arquivo de configuração do ly criado"

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
sudo systemctl enable ly
log::success "ly habilitado com sucesso"

# Verificar se awesome está instalado para compatibilidade
if ! command -v awesome >/dev/null 2>&1; then
    log::warn "Awesome WM não encontrado. Certifique-se de instalá-lo para usar como ambiente de desktop."
else
    log::info "Awesome WM encontrado - compatibilidade verificada"
fi

# Informações finais
log::section "Configuração concluída"
log::success "ly foi configurado como gerenciador de login"
log::info "Para usar o ly:"
log::info "  1. Reinicie o sistema ou execute: sudo systemctl start ly"
log::info "  2. Na tela de login, selecione sua sessão (Awesome WM estará disponível)"
log::info "  3. Digite seu usuário e senha"
log::info ""
log::info "Configurações adicionais podem ser feitas em: /etc/ly/config.ini"