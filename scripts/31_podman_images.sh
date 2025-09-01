#!/usr/bin/env bash
# Faz pull das imagens desejadas para uso no Podman
# - Lê de config/podman-images.txt por padrão (comentários e linhas vazias são ignorados)
# - Pode receber IMAGES (lista separada por espaço/linha) via variável de ambiente
# - Suporta paralelismo com MAX_PARALLEL (padrão 3); use 1 para sequencial
# - Retry simples (até 3 tentativas por imagem)
# - Login opcional em registro via PODMAN_REGISTRY, PODMAN_USERNAME, PODMAN_PASSWORD
# Uso:
#   bash scripts/31_podman_images.sh
#   IMAGES="alpine busybox" MAX_PARALLEL=4 bash scripts/31_podman_images.sh
#   PODMAN_REGISTRY=ghcr.io PODMAN_USERNAME=me PODMAN_PASSWORD=token bash scripts/31_podman_images.sh

set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
if [[ -z "${BASH_VERSION:-}" ]]; then exec bash "$0" "$@"; fi
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/log.sh"

log::section "Baixando imagens do Podman"

# 1) Verificar Podman instalado
if ! command -v podman >/dev/null 2>&1; then
  log::warn "Podman não encontrado. Instale com: bash scripts/30_podman.sh"
  exit 1
fi

# 2) Coletar lista de imagens
CONFIG_FILE="$ROOT_DIR/config/podman-images.txt"
IMAGES_INPUT="${IMAGES:-}"

readarray -t images_from_file < <(test -f "$CONFIG_FILE" && grep -vE '^[[:space:]]*(#|$)' "$CONFIG_FILE" || true)

# Se IMAGES foi fornecido, particiona por espaços e quebras de linha
if [[ -n "$IMAGES_INPUT" ]]; then
  # converte espaços em quebras de linha e filtra vazios
  mapfile -t images_from_env < <(tr ' ' '\n' <<<"$IMAGES_INPUT" | sed '/^\s*$/d')
else
  images_from_env=()
fi

# Unir listas, removendo duplicatas, preservando ordem (arquivo primeiro, depois env)
declare -A seen=()
images=()
for img in "${images_from_file[@]}" "${images_from_env[@]}"; do
  [[ -z "${img:-}" ]] && continue
  if [[ -z "${seen[$img]:-}" ]]; then
    images+=("$img")
    seen[$img]=1
  fi
done

if [[ ${#images[@]} -eq 0 ]]; then
  log::warn "Nenhuma imagem informada. Adicione em $CONFIG_FILE ou use IMAGES=..."
  exit 0
fi

# 3) Login opcional
if [[ -n "${PODMAN_REGISTRY:-}" ]] || [[ -n "${PODMAN_USERNAME:-}" ]] || [[ -n "${PODMAN_PASSWORD:-}" ]]; then
  if [[ -z "${PODMAN_REGISTRY:-}" || -z "${PODMAN_USERNAME:-}" || -z "${PODMAN_PASSWORD:-}" ]]; then
    log::error "Para login, defina PODMAN_REGISTRY, PODMAN_USERNAME e PODMAN_PASSWORD"
    exit 1
  fi
  log::info "Efetuando login em $PODMAN_REGISTRY..."
  if ! printf '%s' "$PODMAN_PASSWORD" | podman login "$PODMAN_REGISTRY" --username "$PODMAN_USERNAME" --password-stdin; then
    log::error "Falha no login do registro $PODMAN_REGISTRY"
    exit 1
  fi
  log::success "Login realizado com sucesso em $PODMAN_REGISTRY"
fi

# 4) Função de pull com retry
pull_one() {
  local image="$1"
  local attempts=0
  local max_attempts=${MAX_ATTEMPTS:-3}
  local delay=2
  while (( attempts < max_attempts )); do
    attempts=$((attempts+1))
    log::info "Pull ($attempts/$max_attempts): $image"
    if podman pull "$image"; then
      log::success "OK: $image"
      return 0
    fi
    log::warn "Falha ao puxar $image (tentativa $attempts). Nova tentativa em ${delay}s..."
    sleep "$delay"
    delay=$((delay*2))
  done
  log::error "Erro definitivo ao puxar $image"
  return 1
}

# 5) Paralelismo com jobs em background (sem xargs)
MAX_PARALLEL="${MAX_PARALLEL:-3}"
if ! [[ "$MAX_PARALLEL" =~ ^[0-9]+$ ]]; then
  log::warn "MAX_PARALLEL inválido: $MAX_PARALLEL. Usando 3."
  MAX_PARALLEL=3
fi

pids=()
fails=0

for img in "${images[@]}"; do
  # Limita número de jobs concorrentes
  while (( $(jobs -pr | wc -l) >= MAX_PARALLEL )); do
    # espera qualquer job terminar
    if ! wait -n; then
      # contabiliza falha sem interromper os demais
      fails=$((fails+1)) || true
    fi
  done
  pull_one "$img" &
  pids+=("$!")
done

# Espera todos os jobs remanescentes
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    fails=$((fails+1)) || true
  fi
done

if (( fails > 0 )); then
  log::error "Uma ou mais imagens falharam ($fails)"
  exit 1
fi

log::success "Todas as imagens processadas"
