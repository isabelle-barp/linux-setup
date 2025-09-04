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
2. **30_podman.sh**: Instalação e configuração do Podman.
3. **31_podman_images.sh**: Download (pull) de imagens do Podman a partir de uma lista.
4. **32_gitkraken.sh**: Instala/atualiza GitKraken (.deb) e cria atalho.
5. **33_station.sh**: Instala o Station via .deb ou AppImage como fallback.
6. **34_toolbox.sh**: Configurações e ferramentas adicionais.
7. **35_obsidian.sh**: Instala/atualiza Obsidian (.deb preferencial, AppImage fallback) e cria atalho.
8. **36_node.sh**: Instalação e configuração do Node.js usando NVM.
9. **37_1password_cli.sh**: Instala/atualiza o 1Password CLI (op) a partir do repositório oficial.
10. **51_python.sh**: Instala Python 3, venv, pip e pipx; ajusta PATH para ~/.local/bin.
11. **50_fonts.sh**: Instala fontes.
12. **59_startship.sh**: Instalação e configuração do prompt Starship.
13. **60_shell_ohmyzsh.sh**: Configuração do shell Zsh com Oh My Zsh.
14. **61_swap_alt_super.sh**: Alterna as teclas Alt e Super no teclado.
15. **62_open_apps_shortcuts.sh**: Atalhos de apps.
16. **63_cmd_shortcuts.sh**: Atalhos de comandos.
17. **64_fn_keys.sh**: Ajustes de teclas Fn.
18. **65_aider.sh**: Instala o Aider (aider-chat) via pipx, com integrações para provedores (OpenAI/Anthropic/Gemini/Groq).
19. **66_github_cli.sh**: Instala/atualiza o GitHub CLI (gh) via repositório oficial.
20. **70_dotfiles.sh**: Gerenciamento de dotfiles.
21. **90_cleanup.sh**: Limpeza final.

Cada script pode ser executado diretamente com o comando `bash` ou conforme descrito em seus comentários.

### Aider (IA no terminal)

- Instalação automática pelo bootstrap ou manualmente:
  
  ```bash
  bash scripts/51_python.sh
  bash scripts/65_aider.sh
  ```

- Após instalar, você pode configurar as chaves de API via 1Password CLI usando nosso dotfile zsh:
  
  ```bash
  # Instale o 1Password CLI e faça login: bash scripts/37_1password_cli.sh && op signin
  # Aplique os dotfiles (inclui ~/.zshrc com alias):
  bash scripts/70_dotfiles.sh zsh
  # No shell zsh, carregue as chaves na sessão atual:
  aider-keys
  ```
  
  Por padrão, o dotfile procura itens no cofre "Private" com nomes "OpenAI API Key" e "Anthropic API Key" e campo "api_key". Você pode ajustar via variáveis: `OP_VAULT`, `OP_ITEM_OPENAI`, `OP_ITEM_ANTHROPIC`, `OP_FIELD_OPENAI`, `OP_FIELD_ANTHROPIC`.
  
  Guia completo: docs/1password_api_keys.md
  
  Alternativamente, exporte manualmente:
  
  ```bash
  export OPENAI_API_KEY=...
  export ANTHROPIC_API_KEY=...
  export GEMINI_API_KEY=...
  export GROQ_API_KEY=...
  ```

- Uso básico (em um repositório Git):
  
  ```bash
  aider .
  ```

## Podman

Instalar e preparar imagens do Podman:

1. Instalar/atualizar Podman:
   
   ```bash
   bash scripts/30_podman.sh
   ```

2. Definir as imagens a baixar no arquivo de configuração (um nome por linha; comentários com # e linhas vazias são ignorados):
   
   Arquivo: `config/podman-images.txt`
   
   Exemplos de linhas válidas:
   - docker.io/library/alpine:latest
   - docker.io/library/busybox:stable
   - quay.io/podman/hello:latest
   - ghcr.io/cli/cli:latest

3. Baixar (pull) as imagens:
   
   ```bash
   bash scripts/31_podman_images.sh
   ```

Opções por variáveis de ambiente:
- IMAGES: lista alternativa de imagens (separadas por espaço ou quebra de linha). Ex.: `IMAGES="alpine busybox" bash scripts/31_podman_images.sh`
- MAX_PARALLEL: grau de paralelismo (padrão: 3). Use `1` para sequencial.
- MAX_ATTEMPTS: tentativas por imagem (padrão: 3; backoff exponencial entre tentativas).
- Login opcional em registro: defina `PODMAN_REGISTRY`, `PODMAN_USERNAME`, `PODMAN_PASSWORD` para autenticar antes do pull.

Exemplos:
```bash
# Puxar imagens definidas no arquivo com 4 downloads em paralelo
MAX_PARALLEL=4 bash scripts/31_podman_images.sh

# Puxar lista ad-hoc sem usar arquivo
IMAGES="docker.io/library/alpine:latest ghcr.io/cli/cli:latest" bash scripts/31_podman_images.sh

# Fazer login no GHCR e puxar imagens
PODMAN_REGISTRY=ghcr.io PODMAN_USERNAME=seu_usuario PODMAN_PASSWORD=seu_token bash scripts/31_podman_images.sh
```