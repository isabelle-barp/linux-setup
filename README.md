# linux-setup

Automação reprodutível para Arch Linux: pacotes (pacman/AUR), Zsh + Oh My Zsh, gerenciador de login ly e dotfiles via GNU Stow.

## Requisitos
- Arch Linux (ou derivado compatível com pacman)
- Internet ativa e sudo configurado

## Uso
```bash
./bootstrap.sh
```

O bootstrap:
- Verifica sistema e internet
- Carrega variáveis do arquivo .env (se existir) no formato KEY=VALUE, linhas comentadas com # são ignoradas
- Executa os scripts na ordem correta (veja abaixo)

## Setup
Se necessário, torne os scripts executáveis:
```bash
chmod +x scripts/*.sh
```

## Scripts disponíveis (ordem de execução)
- 00_pacman.sh: Atualiza o sistema e instala pacotes oficiais listados em config/pacman-packages.txt
- 01_yay.sh: Instala/atualiza o yay e instala pacotes do AUR listados em config/aur-packages.txt
- 02_zsh.sh: Define o Zsh como shell padrão (exige o pacote zsh já instalado)
- 03_shell_ohmyzsh.sh: Instala/atualiza Oh My Zsh e plugins (zsh-autosuggestions, zsh-syntax-highlighting), ajusta ~/.zshrc
  - Variáveis opcionais: SHELL_SET_DEFAULT=1, ZSH_THEME=robbyrussell, EXTRA_PLUGINS="git"
- 10_ly.sh: Instala e habilita o gerenciador de login ly (desabilita outros DMs), cria /etc/ly/config.ini se ausente
- 80_dotfiles.sh: Aplica dotfiles com GNU Stow a partir da pasta dotfiles/
  - Uso: bash scripts/80_dotfiles.sh [pacotes...]; sem argumentos aplica todos os subdiretórios
  - Variáveis: STOW_ADOPT=1 para --adopt; DOTFILES_REPLACE=0 para não substituir arquivos existentes
- 90_cleanup.sh: Limpeza final (remove pacotes órfãos e limpa cache do pacman)

## Configurações
- config/pacman-packages.txt: lista de pacotes dos repositórios oficiais (uma entrada por linha; # e linhas vazias são ignoradas)
- config/aur-packages.txt: lista de pacotes do AUR (uma por linha; # e linhas vazias são ignoradas)

## Observações
- Você pode executar qualquer script individualmente com bash scripts/NOME.sh
- Após mudar o shell para Zsh, abra um novo terminal ou rode: exec zsh
- Para personalizar o tema/plugins do Zsh, use variáveis ao chamar 03_shell_ohmyzsh.sh, por exemplo:
  ```bash
  ZSH_THEME=agnoster EXTRA_PLUGINS="git kubectl" bash scripts/03_shell_ohmyzsh.sh
  ```