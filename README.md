# linux-setup


Automação reprodutível para ElementaryOS: pacotes, Flatpak, Docker, devtools, linguagens, ajustes de desktop e NoMachine.


## Uso
```bash
./bootstrap.sh
```

## Setup
```bash
chmod +x scripts/*.sh
```

## Scripts Disponíveis

Abaixo está a lista de scripts disponíveis no diretório `scripts`:

1. **10_apt.sh**: Configurações relacionadas ao gerenciador de pacotes APT.
2. **36_node.sh**: Instalação e configuração do Node.js usando NVM.
3. **33_station.sh**: Configurações específicas para o aplicativo Station.
4. **59_startship.sh**: Instalação e configuração do prompt Starship.
5. **70_dotfiles.sh**: Gerenciamento de pacotes definidos em arquivos dotfiles.
6. **60_shell_ohmyzsh.sh**: Configuração do shell Zsh com Oh My Zsh.
7. **34_toolbox.sh**: Configurações e ferramentas adicionais.
8. **61_swap_alt_super.sh**: Alterna as teclas Alt e Super no teclado.

Cada script pode ser executado diretamente com o comando `bash` ou conforme descrito em seus comentários.