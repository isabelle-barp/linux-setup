#!/usr/bin/env bash
# docker-clean-all.sh — Remove containers, images, volumes, networks and builder cache.
#
# Usage:
#   docker-clean-all.sh [--force] [--podman]
#
# Notes:
# - Defaults to Docker if available; falls back to Podman with --podman or if docker isn’t found.
# - --force skips interactive confirmation.
# - Excludes default networks: bridge, host, none.
#
set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x
trap 's=$?; echo -e "\e[31m[ERROR]\e[0m ${BASH_SOURCE[0]}:${LINENO}: ${BASH_COMMAND} (exit $s)" >&2; exit $s' ERR

confirm() {
  local msg=${1:-"Proceed?"}
  if [[ "${FORCE:-0}" == "1" ]]; then
    return 0
  fi
  read -r -p "$msg [y/N]: " ans || true
  [[ "$ans" =~ ^[Yy]$ ]]
}

FORCE=0
ENGINE=""

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE=1 ;;
    --podman)
      ENGINE=podman ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2 ;;
  esac
done

# Detect container engine
if [[ -z "$ENGINE" ]]; then
  if command -v docker >/dev/null 2>&1; then
    ENGINE=docker
  elif command -v podman >/dev/null 2>&1; then
    ENGINE=podman
  else
    echo "No container engine found (docker or podman)." >&2
    exit 1
  fi
fi

say() { echo -e "\e[1;33m-->\e[0m $*"; }
ok() { echo -e "\e[32m✓\e[0m $*"; }

say "Using engine: $ENGINE"

if ! confirm "This will STOP and REMOVE ALL containers, images, volumes, and non-default networks for $ENGINE. Continue?"; then
  echo "Aborted."; exit 0
fi

# Stop all running containers
if ids=$($ENGINE ps -q); [[ -n "${ids:-}" ]]; then
  say "Stopping containers..."
  $ENGINE stop $ids >/dev/null || true
  ok "Containers stopped."
else
  say "No running containers."
fi

# Remove all containers
if ids=$($ENGINE ps -aq); [[ -n "${ids:-}" ]]; then
  say "Removing containers..."
  $ENGINE rm -f $ids >/dev/null || true
  ok "Containers removed."
else
  say "No containers to remove."
fi

# Remove all images
if imgs=$($ENGINE images -q); [[ -n "${imgs:-}" ]]; then
  say "Removing images..."
  $ENGINE rmi -f $imgs >/dev/null || true
  ok "Images removed."
else
  say "No images to remove."
fi

# Remove all volumes
if vols=$($ENGINE volume ls -q 2>/dev/null || true); [[ -n "${vols:-}" ]]; then
  say "Removing volumes..."
  $ENGINE volume rm -f $vols >/dev/null || true
  ok "Volumes removed."
else
  say "No volumes to remove."
fi

# Remove non-default networks
# default networks to keep vary; for docker: bridge host none; for podman similar concepts
mapfile -t nets < <($ENGINE network ls -q 2>/dev/null || true)
if ((${#nets[@]} > 0)); then
  say "Removing non-default networks..."
  for nid in "${nets[@]}"; do
    name=$($ENGINE network inspect -f '{{.Name}}' "$nid" 2>/dev/null || echo "")
    case "$name" in
      bridge|host|none|podman|podman-default|podman-infra)
        continue ;;
      *)
        $ENGINE network rm "$nid" >/dev/null || true ;;
    esac
  done
  ok "Networks cleaned."
else
  say "No user networks to remove."
fi

# Builder cache prune (best-effort)
if [[ "$ENGINE" == "docker" ]]; then
  $ENGINE builder prune -af >/dev/null 2>&1 || true
elif [[ "$ENGINE" == "podman" ]]; then
  $ENGINE system prune -af >/dev/null 2>&1 || true
fi
ok "Builder/system cache pruned."

ok "All done."