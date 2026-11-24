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

# Startup time, 10 runs (timed by zsh itself; /usr/bin/time isn't everywhere).
zbench() {
  zmodload zsh/datetime
  local i t
  for i in {1..10}; do
    t=$EPOCHREALTIME
    zsh -i -c exit >/dev/null 2>&1
    printf '%.3fs\n' $(( EPOCHREALTIME - t ))
  done
}
