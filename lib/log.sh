#!/usr/bin/env bash
set -euo pipefail


log::title(){ echo -e "\n\e[1;34m==> $*\e[0m"; }
log::section(){ echo -e "\n\e[1;33m--> $*\e[0m"; }
log::info(){ echo -e "[INFO] $*"; }
log::warn(){ echo -e "\e[33m[WARN]\e[0m $*"; }
log::error(){ echo -e "\e[31m[ERROR]\e[0m $*"; }
log::success(){ echo -e "\e[32m✓ $*\e[0m"; }
