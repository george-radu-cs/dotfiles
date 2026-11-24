# shellcheck shell=bash
# Post-link setup: login shell, tmux plugins, neovim plugins, default theme.

setup_shell() {
  local zsh_path
  if ! zsh_path=$(command -v zsh); then
    [[ $DRY_RUN == 1 ]] || die "zsh not installed"
    zsh_path=/bin/zsh   # dry run before the packages step installed it
  fi

  if [[ ${SHELL:-} != "$zsh_path" && $(basename "${SHELL:-}") != zsh ]]; then
    if ! grep -qx "$zsh_path" /etc/shells; then
      echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null
    fi
    if [[ $EUID -eq 0 ]]; then
      warn "running as root — skipped chsh"
    else
      run chsh -s "$zsh_path" && ok "login shell → $zsh_path (takes effect on next login)"
    fi
  else
    ok "login shell is zsh"
  fi

  # History moved from ~/.zsh_history to the XDG state dir; carry it over once.
  local hist="$XDG_STATE_HOME/zsh/history"
  if [[ -s $HOME/.zsh_history && ! -e $hist ]]; then
    run mkdir -p "$(dirname "$hist")"
    run cp "$HOME/.zsh_history" "$hist"
    ok "copied ~/.zsh_history → $(tilde "$hist")"
  fi

  # antidote (zsh plugin manager); .zshrc also self-installs it if missing.
  local antidote="$XDG_DATA_HOME/antidote"
  [[ -d $antidote ]] || run git clone --depth=1 --quiet https://github.com/mattmc3/antidote.git "$antidote"
  ok "antidote ready"
}

setup_tmux() {
  local tpm="$XDG_DATA_HOME/tmux/plugins/tpm"
  [[ -d $tpm ]] || run git clone --depth=1 --quiet https://github.com/tmux-plugins/tpm "$tpm"
  # tpm's installer needs the config path and a (temporary) server.
  if [[ $DRY_RUN != 1 ]] && has tmux; then
    if TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME/tmux/plugins/" "$tpm/bin/install_plugins" >/dev/null 2>&1; then
      ok "tmux plugins installed"
    else
      warn "tmux plugin install failed — press prefix + I inside tmux"
    fi
  fi
}

# tealdeer (`tldr`) ships without pages; download them once.
setup_tldr() {
  has tldr || return 0
  if tldr --list >/dev/null 2>&1; then
    ok "tldr pages present"
  else
    if run tldr --update >/dev/null 2>&1; then
      ok "tldr pages downloaded"
    else
      warn "tldr pages could not be downloaded — run: tldr --update"
    fi
  fi
}

setup_nvim() {
  has nvim || { warn "nvim not found — skipped plugin sync"; return; }
  if run nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1; then
    ok "neovim plugins match lazy-lock.json"
  else
    warn "neovim plugin restore failed — open nvim and run :Lazy restore"
  fi
}

setup_theme() {
  local state="$XDG_STATE_HOME/dotfiles/theme/name"
  if [[ ! -f $state ]]; then
    run "$DOTFILES/home/bin/.local/bin/theme" gruvbox >/dev/null
  fi
  local name=gruvbox
  [[ -f $state ]] && name=$(<"$state")
  ok "theme: $name   $(hint "switch with: theme <name>")"
  note "zsh · antidote · tmux plugins · nvim plugins · theme $name"
}
