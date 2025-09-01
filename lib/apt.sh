# lib/apt.sh
aptq() {
  local front="${DEBIAN_FRONTEND:-noninteractive}"
  # Se DEBUG=1, não silencia
  if [[ "${DEBUG:-0}" == "1" ]]; then
    sudo DEBIAN_FRONTEND="$front" apt-get -y -o=Dpkg::Use-Pty=0 -o=Dpkg::Progress-Fancy=0 "$@"
  else
    sudo DEBIAN_FRONTEND="$front" apt-get -y -qq -o=Dpkg::Use-Pty=0 -o=Dpkg::Progress-Fancy=0 "$@"
  fi
}
