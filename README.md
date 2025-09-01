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
