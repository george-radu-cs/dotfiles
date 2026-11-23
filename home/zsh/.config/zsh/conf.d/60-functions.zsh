# Small helpers.

# dots            → lazygit in the dotfiles repo (stage, commit, push)
# dots <git args> → git in the dotfiles repo, e.g. `dots status`, `dots pull`
dots() {
  if (( $# )); then
    git -C "$DOTFILES" "$@"
  elif (( $+commands[lazygit] )); then
    lazygit -p "$DOTFILES"
  else
    cd "$DOTFILES"
  fi
}

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# yazi file manager; cd into the last directory on exit.
y() {
  local tmp cwd
  tmp=$(mktemp -t yazi-cwd.XXXXXX)
  yazi "$@" --cwd-file="$tmp"
  cwd=$(<"$tmp")
  [[ -n $cwd && $cwd != $PWD ]] && cd -- "$cwd"
  rm -f -- "$tmp"
}

# Startup time, 10 runs.
zbench() {
  local i
  for i in {1..10}; do /usr/bin/time zsh -i -c exit; done 2>&1 | awk '/real/ {print $1 "s"}'
}
