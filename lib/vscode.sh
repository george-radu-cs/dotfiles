# shellcheck shell=bash
# VS Code: settings and keybindings from vscode/ (linked), extensions from
# vscode/extensions.txt. VS Code's user folder differs per OS, which stow's
# mirror-of-$HOME layout can't express, so the two files are linked directly.
# VS Code writes through the links, so changes made in its UI land in the repo.

VSCODE_REPO="$DOTFILES/vscode"
VSCODE_FILES=(settings.json keybindings.json)

vscode_user_dir() {
  if is_macos; then printf '%s' "$HOME/Library/Application Support/Code/User"
  else printf '%s' "$XDG_CONFIG_HOME/Code/User"; fi
}

_vscode_cli() {
  if has code; then command -v code
  elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    printf '%s' "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  fi
}

_vscode_wanted() { read_list "$VSCODE_REPO/extensions.txt" | tr '[:upper:]' '[:lower:]'; }

link_vscode() {
  local dir f target linked=0
  dir=$(vscode_user_dir)
  run mkdir -p "$dir"
  for f in "${VSCODE_FILES[@]}"; do
    target="$dir/$f"
    _links_into_repo "$target" && continue
    [[ -e $target || -L $target ]] && backup "$target"
    run ln -s "$VSCODE_REPO/$f" "$target"
    linked=$((linked + 1))
  done
  ok "VS Code: settings and keybindings linked$( (( linked == 0 )) && printf ' (already)')"
}

unlink_vscode() {
  local dir f
  dir=$(vscode_user_dir)
  for f in "${VSCODE_FILES[@]}"; do
    if _links_into_repo "$dir/$f"; then run rm "$dir/$f"; fi
  done
}

# Install the extensions from the list that are missing. Never removes any;
# `dotctl prune` lists the extras.
install_vscode_extensions() {
  local cli
  cli=$(_vscode_cli)
  if [[ -z $cli ]]; then
    info "VS Code not installed — skipped extensions"
    return 0
  fi
  local installed missing=() id
  installed=" $("$cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr '\n' ' ') "
  while IFS= read -r id; do
    [[ $installed == *" $id "* ]] || missing+=("$id")
  done < <(_vscode_wanted)
  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "VS Code: all $(_vscode_wanted | wc -l | tr -d ' ') extensions installed"
    return 0
  fi
  info "VS Code: installing ${#missing[@]} extensions…"
  for id in "${missing[@]}"; do
    run "$cli" --install-extension "$id" --force >/dev/null 2>&1 || warn "could not install $id"
  done
  ok "VS Code: extensions installed"
}

# Extensions installed but not in vscode/extensions.txt (for prune / doctor).
vscode_extra_extensions() {
  local cli
  cli=$(_vscode_cli)
  [[ -n $cli ]] || return 0
  "$cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -v -x -F -f <(_vscode_wanted) || true
}
