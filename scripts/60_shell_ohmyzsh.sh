#!/usr/bin/env bash
# Instala Zsh + Oh My Zsh (idempotente) no ElementaryOS/Ubuntu-like
# Uso:
#   bash scripts/60_shell_ohmyzsh.sh
# Variáveis opcionais:
#   SHELL_SET_DEFAULT=0   # não trocar o shell padrão (default: 1)
#   ZSH_THEME=robbyrussell # tema do Oh My Zsh (default: robbyrussell)
#   EXTRA_PLUGINS="git"    # plugins extras além dos padrão (serão mesclados)

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

# Paths do repo e logger
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if [[ ! -r "$ROOT_DIR/lib/log.sh" ]]; then
  echo "[ERROR] logger ausente: $ROOT_DIR/lib/log.sh" >&2
  exit 2
fi
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/apt.sh"

# Config
SHELL_SET_DEFAULT="${SHELL_SET_DEFAULT:-1}"
ZSH_THEME="${ZSH_THEME:-robbyrussell}"
EXTRA_PLUGINS="${EXTRA_PLUGINS:-}"

log::section "Instalando Zsh + Oh My Zsh"

# Dependências
aptq update
aptq install zsh git curl ca-certificates || true

# Instala Oh My Zsh de forma idempotente (clone direto, sem rodar script remoto)
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -d "$ZSH_DIR" ]]; then
  log::info "Oh My Zsh já presente em $ZSH_DIR"
  (cd "$ZSH_DIR" && git fetch --quiet --all && git pull --quiet || true)
else
  log::info "Clonando Oh My Zsh em $ZSH_DIR"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
fi

# Plugins recomendados
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

# zsh-autosuggestions
if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  (cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git fetch --quiet --all && git pull --quiet || true)
else
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  (cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git fetch --quiet --all && git pull --quiet || true)
else
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# .zshrc — criar mínimo se não existir; senão ajustar de forma segura
ZSHRC="$HOME/.zshrc"
if [[ ! -f "$ZSHRC" ]]; then
  log::info "Criando ~/.zshrc"
  cat > "$ZSHRC" <<EOF
export ZSH="$ZSH_DIR"
ZSH_THEME="$ZSH_THEME"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting${EXTRA_PLUGINS:+ $EXTRA_PLUGINS})
source "\$ZSH/oh-my-zsh.sh"

# PATH do usuário
export PATH="\$HOME/.local/bin:\$PATH"

# NVM (se existir)
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"

# Starship (se instalado)
command -v starship >/dev/null 2>&1 && eval "\$(starship init zsh)"
EOF
else
  log::info "Atualizando ~/.zshrc (backup em ~/.zshrc.bak)"
  cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"

  # Garante export ZSH
  grep -q '^export ZSH=' "$ZSHRC" || echo "export ZSH=\"$ZSH_DIR\"" >> "$ZSHRC"

  # Ajusta ZSH_THEME (ou adiciona se não tiver)
  if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed -i -E "s|^ZSH_THEME=.*$|ZSH_THEME=\"$ZSH_THEME\"|" "$ZSHRC"
  else
    echo "ZSH_THEME=\"$ZSH_THEME\"" >> "$ZSHRC"
  fi

  # Garante os plugins recomendados na linha plugins=(...)
  if grep -qE '^plugins=\(' "$ZSHRC"; then
    # Normaliza e injeta plugins se faltarem
    for p in git zsh-autosuggestions zsh-syntax-highlighting $EXTRA_PLUGINS; do
      grep -qE "plugins=.*\b$p\b" "$ZSHRC" || \
        sed -i -E "s/^plugins=\(([^)]*)\)/plugins=(\1 $p)/" "$ZSHRC"
    done
  else
    echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting${EXTRA_PLUGINS:+ $EXTRA_PLUGINS})" >> "$ZSHRC"
  fi

  # Garante source do omz
  grep -q 'oh-my-zsh.sh' "$ZSHRC" || echo 'source "$ZSH/oh-my-zsh.sh"' >> "$ZSHRC"

  # PATH do usuário
  grep -q '\.local/bin' "$ZSHRC" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"

  # NVM hooks (se não existirem)
  grep -q 'NVM_DIR' "$ZSHRC" || cat >> "$ZSHRC" <<'EOFNVM'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOFNVM

  # Starship (se instalado)
  grep -q 'starship init zsh' "$ZSHRC" || \
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"' >> "$ZSHRC"
fi

# Define Zsh como shell padrão (opcional)
if [[ "$SHELL_SET_DEFAULT" == "1" ]]; then
  ZSH_BIN="$(command -v zsh || true)"
  if [[ -n "$ZSH_BIN" && "${SHELL:-}" != "$ZSH_BIN" ]]; then
    log::info "Trocando shell padrão para: $ZSH_BIN (pode pedir sua senha)"
    chsh -s "$ZSH_BIN" "$USER" || {
      log::warn "Não foi possível rodar chsh automaticamente. Troque manualmente com: chsh -s \"$ZSH_BIN\" \"$USER\""
    }
  else
    log::info "Zsh já é o shell padrão."
  fi
else
  log::info "SHELL_SET_DEFAULT=0 — não alterando o shell padrão."
fi

log::success "Zsh + Oh My Zsh prontos. Abra um novo terminal (ou rode: exec zsh)"
