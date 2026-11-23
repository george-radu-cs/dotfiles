# shellcheck shell=bash
# Docker Engine from Docker's own repositories (Linux) or Docker Desktop (macOS).

install_docker() {
  case $DOTFILES_OS in
    macos)
      # docker-desktop is in the Brewfile; nothing else to do.
      if [[ -d /Applications/Docker.app ]]; then
        ok "Docker Desktop $(defaults read /Applications/Docker.app/Contents/Info CFBundleShortVersionString 2>/dev/null)"
        note "Docker Desktop (Homebrew cask)"
      else warn "Docker Desktop missing — run the packages step"; note "Docker Desktop missing"; fi
      return ;;
    arch)   ;; # docker, docker-compose, docker-buildx are in packages/arch.txt
    fedora) _docker_repo_fedora ;;
    debian) _docker_repo_debian ;;
  esac
  _docker_configure_linux
}

_docker_repo_fedora() {
  if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
    local repo=https://download.docker.com/linux/fedora/docker-ce.repo
    if dnf --version 2>/dev/null | grep -q '^dnf5'; then
      as_root dnf -y config-manager addrepo --from-repofile="$repo"
    else
      as_root dnf -y config-manager --add-repo "$repo"
    fi
  fi
  as_root dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_docker_repo_debian() {
  local ID="" VERSION_CODENAME="" UBUNTU_CODENAME=""
  # shellcheck disable=SC1091
  . /etc/os-release
  local distro=debian codename=$VERSION_CODENAME
  if [[ $ID == ubuntu || -n $UBUNTU_CODENAME ]]; then distro=ubuntu; codename=${UBUNTU_CODENAME:-$VERSION_CODENAME}; fi

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    as_root install -d -m 0755 /etc/apt/keyrings
    fetch "https://download.docker.com/linux/$distro/gpg" /tmp/docker.asc
    as_root install -m 0644 /tmp/docker.asc /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$distro $codename stable" \
      | as_root tee /etc/apt/sources.list.d/docker.list >/dev/null
    as_root apt-get update -qq
  fi
  as_root apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_docker_configure_linux() {
  local src="$DOTFILES/system/docker/daemon.json" dst=/etc/docker/daemon.json
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    as_root install -d -m 0755 /etc/docker
    [[ -f $dst ]] && as_root cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    as_root install -m 0644 "$src" "$dst"
    ok "installed $dst"
  fi

  if [[ -d /run/systemd/system ]]; then
    as_root systemctl enable --now containerd.service docker.service
  else
    warn "systemd not running (container?) — skipped enabling docker.service"
  fi

  if [[ $EUID -ne 0 ]] && ! id -nG "$USER" | grep -qw docker; then
    as_root usermod -aG docker "$USER"
    warn "added $USER to the docker group — log out and back in for it to apply"
  fi
  ok "docker configured"
  note "Docker Engine $(docker --version 2>/dev/null | awk '{ print $3 }' | tr -d ',') + compose + buildx"
}
