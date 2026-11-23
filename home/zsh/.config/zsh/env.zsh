# Environment and PATH for every zsh. Sourced from ~/.zshenv and again from
# .zprofile, because macOS's /etc/zprofile (path_helper) reorders PATH for
# login shells. `typeset -U` keeps entries unique, so re-sourcing is harmless.

typeset -gU path fpath manpath

# --- Homebrew (static equivalent of `brew shellenv`, no subprocess) ----------
for _brew in /opt/homebrew /home/linuxbrew/.linuxbrew /usr/local; do
  if [[ -x $_brew/bin/brew ]]; then
    export HOMEBREW_PREFIX=$_brew
    export HOMEBREW_CELLAR=$_brew/Cellar
    if [[ $_brew == /opt/homebrew ]]; then export HOMEBREW_REPOSITORY=$_brew
    else export HOMEBREW_REPOSITORY=$_brew/Homebrew; fi
    path=($_brew/bin $_brew/sbin $path)
    fpath=($_brew/share/zsh/site-functions $fpath)
    manpath=($_brew/share/man $manpath '')
    export INFOPATH="$_brew/share/info${INFOPATH:+:$INFOPATH}"
    break
  fi
done
unset _brew
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# --- language / SDK homes ------------------------------------------------------
export GOPATH="$HOME/go"
if [[ $OSTYPE == darwin* ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
else
  export ANDROID_HOME="$HOME/Android/Sdk"
  export MISE_ENV=linux   # loads ~/.config/mise/config.linux.toml (CLI tools)
fi

# --- PATH: personal bins first, then anything that exists ----------------------
# (N-/) keeps only directories that actually exist on this machine.
path=(
  $HOME/.local/bin
  $XDG_DATA_HOME/mise/shims       # non-interactive shells; .zshrc activates mise properly
  $HOME/.cargo/bin
  $path
  $GOPATH/bin(N-/)
  $HOME/.bun/bin(N-/)
  $HOME/.pub-cache/bin(N-/)
  $HOME/development/flutter/bin(N-/)
  $HOME/.ghcup/bin(N-/)
  $ANDROID_HOME/emulator(N-/)
  $ANDROID_HOME/platform-tools(N-/)
  $ANDROID_HOME/cmdline-tools/latest/bin(N-/)
  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"(N-/)
  $XDG_DATA_HOME/JetBrains/Toolbox/scripts(N-/)
)

# --- defaults ------------------------------------------------------------------
export LANG="${LANG:-en_US.UTF-8}"
if [[ -n $SSH_CONNECTION ]] || (( ! $+commands[nvim] )); then
  export EDITOR=vim
else
  export EDITOR=nvim
fi
export VISUAL=$EDITOR
export PAGER=less
export LESS='-R --mouse'
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
