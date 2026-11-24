# shellcheck shell=bash
# System packages per platform. Everything here is safe to re-run.

install_packages() {
  case $DOTFILES_OS in
    macos)  _packages_macos ;;
    arch)   _packages_arch ;;
    fedora) _packages_fedora ;;
    debian) _packages_debian ;;
  esac
  if is_linux; then _install_mise_linux; _install_wrk_linux; install_flatpaks; fi
}

# --- macOS -------------------------------------------------------------------

_packages_macos() {
  if ! xcode-select -p >/dev/null 2>&1; then
    info "installing Xcode Command Line Tools (a dialog will open)…"
    run xcode-select --install || true
    [[ $DRY_RUN == 1 ]] || until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  fi

  if ! has brew; then
    info "installing Homebrew…"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Apple Silicon Homebrew wins; /usr/local is only used on Intel Macs (an
  # Intel/Rosetta install there, e.g. for `ibrew`, must not take over PATH).
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  _brew_bundle "$DOTFILES/packages/Brewfile"
  if [[ ${WITH_EXTRA:-0} == 1 ]]; then
    _brew_bundle "$DOTFILES/packages/Brewfile.extra"
  fi
}

# Entries `brew bundle check` reports as missing, one name per line.
_brew_missing() {
  brew bundle check --no-upgrade --verbose --file "$1" 2>&1 \
    | sed -nE 's/^→ [A-Za-z]+ (.+) needs to be [a-z]+\.?$/\1/p' || true
}

# brew bundle with a summary before (what is missing) and after (what got
# installed). Homebrew's own output goes straight to the terminal: it draws its
# live, parallel-download progress only when stdout is a TTY.
_brew_bundle() {
  local file=$1 name total before=() after=() t0=$SECONDS rc=0
  total=$(grep -cE '^(tap|brew|cask|mas) ' "$file")
  while IFS= read -r name; do [[ -n $name ]] && before+=("$name"); done < <(_brew_missing "$file")

  if [[ ${#before[@]} -eq 0 ]]; then
    ok "$(basename "$file"): all $total entries already installed"
    note "Homebrew: all $total already installed"
    return
  fi
  info "$(basename "$file"): $total entries — $((total - ${#before[@]})) already installed, ${#before[@]} to install:"
  columns "${before[@]}"

  # --no-upgrade: install what's missing, leave installed packages alone
  # (upgrade deliberately with `brew upgrade`).
  run brew bundle --no-upgrade --file "$file" || rc=$?
  [[ $DRY_RUN == 1 ]] && return

  while IFS= read -r name; do [[ -n $name ]] && after+=("$name"); done < <(_brew_missing "$file")
  local done_count=$(( ${#before[@]} - ${#after[@]} ))
  (( done_count < 0 )) && done_count=0
  ok "installed $done_count/${#before[@]} in $(human_time $((SECONDS - t0)))"
  note "Homebrew: $total entries, $done_count newly installed"
  if [[ ${#after[@]} -gt 0 ]]; then
    warn "still missing (see the errors above):"
    columns "${after[@]}" >&2
    die "$(basename "$file") incomplete — fix the errors above and rerun ./bootstrap.sh packages"
  fi
  (( rc == 0 )) || warn "brew bundle exited with $rc but everything is installed"
}

# --- Arch ----------------------------------------------------------------------

_packages_arch() {
  # shellcheck disable=SC2046
  as_root pacman -Syu --needed --noconfirm $(read_list "$DOTFILES/packages/arch.txt")
  ok "pacman packages installed"
  note "pacman: $(read_list "$DOTFILES/packages/arch.txt" | wc -l | tr -d ' ') packages"
}

# --- Fedora --------------------------------------------------------------------

_packages_fedora() {
  as_root dnf -y install dnf-plugins-core
  if ! dnf copr list 2>/dev/null | grep -q 'wezfurlong/wezterm-nightly'; then
    as_root dnf -y copr enable wezfurlong/wezterm-nightly
  fi
  # shellcheck disable=SC2046
  as_root dnf -y install $(read_list "$DOTFILES/packages/fedora.txt") wezterm
  ok "dnf packages installed"
  note "dnf: $(read_list "$DOTFILES/packages/fedora.txt" | wc -l | tr -d ' ') packages + WezTerm"
}

# --- Debian / Ubuntu ---------------------------------------------------------

_packages_debian() {
  export DEBIAN_FRONTEND=noninteractive
  as_root apt-get update -qq
  # shellcheck disable=SC2046
  as_root apt-get install -y -qq $(read_list "$DOTFILES/packages/debian.txt")

  # en_US.UTF-8 must exist or zsh/tmux complain about the locale.
  if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf-\?8$'; then
    as_root sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    as_root locale-gen
  fi

  # WezTerm's own apt repository (https://wezterm.org/install/linux.html)
  if [[ ! -f /etc/apt/sources.list.d/wezterm.list ]]; then
    as_root install -d -m 0755 /etc/apt/keyrings
    fetch https://apt.fury.io/wez/gpg.key /tmp/wezterm.gpg.key
    as_root gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg /tmp/wezterm.gpg.key
    as_root chmod 644 /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
      | root_write /etc/apt/sources.list.d/wezterm.list
    as_root apt-get update -qq
  fi
  as_root apt-get install -y -qq wezterm
  ok "apt packages installed"
  note "apt: $(read_list "$DOTFILES/packages/debian.txt" | wc -l | tr -d ' ') packages + WezTerm"
}

# --- mise on Linux -------------------------------------------------------------

# Arch packages mise; elsewhere use the official installer (~/.local/bin/mise,
# updated with `mise self-update`).
_install_mise_linux() {
  if has mise || [[ -x $HOME/.local/bin/mise ]]; then
    ok "mise present"
    return
  fi
  info "installing mise…"
  if [[ $DRY_RUN == 1 ]]; then
    run sh -c 'curl -fsSL https://mise.run | sh'
  else
    curl -fsSL https://mise.run | MISE_QUIET=1 sh
  fi
  ok "mise installed"
}

# wrk (HTTP benchmarking): Debian packages it (packages/debian.txt); Arch only
# has it in the AUR and Fedora not at all, and upstream publishes source only,
# so build the pinned release there into ~/.local/bin.
WRK_VERSION="${WRK_VERSION:-4.2.0}"
_install_wrk_linux() {
  has wrk && { ok "wrk present"; return 0; }
  [[ $DOTFILES_OS == debian ]] && return 0
  info "building wrk $WRK_VERSION from source…"
  local src="$XDG_CACHE_HOME/dotfiles/wrk-$WRK_VERSION"
  run rm -rf "$src"
  run git clone --quiet --depth 1 --branch "$WRK_VERSION" https://github.com/wg/wrk.git "$src"
  if run make -C "$src" -j"$(nproc 2>/dev/null || echo 2)" >/dev/null 2>&1; then
    run install -m 0755 "$src/wrk" "$HOME/.local/bin/wrk"
    ok "wrk $WRK_VERSION built into ~/.local/bin"
  else
    warn "wrk build failed — see: make -C $(tilde "$src")"
  fi
}
