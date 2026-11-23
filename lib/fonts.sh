# shellcheck shell=bash
# JetBrainsMono Nerd Font (ligatures included; the "NL" variant is the one
# without). macOS gets it from the Brewfile cask; Linux downloads the same
# pinned release so every machine renders identically.

NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-v3.4.0}"

install_fonts() {
  if is_macos; then
    ok "JetBrainsMono Nerd Font (Homebrew cask)"
    note "JetBrainsMono Nerd Font"
    return
  fi

  local dest="$XDG_DATA_HOME/fonts/JetBrainsMonoNerdFont" stamp
  stamp="$dest/.version"
  if [[ -f $stamp && $(<"$stamp") == "$NERD_FONTS_VERSION" ]]; then
    ok "JetBrainsMono Nerd Font $NERD_FONTS_VERSION present"
    note "JetBrainsMono Nerd Font $NERD_FONTS_VERSION"
    return
  fi

  local tmp
  tmp=$(mktemp -d)
  fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_VERSION/JetBrainsMono.tar.xz" "$tmp/JetBrainsMono.tar.xz"
  run rm -rf "$dest"
  run mkdir -p "$dest"
  run tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$dest" --wildcards '*.ttf'
  [[ $DRY_RUN == 1 ]] || printf '%s\n' "$NERD_FONTS_VERSION" >"$stamp"
  rm -rf "$tmp"
  has fc-cache && run fc-cache -f "$dest" >/dev/null
  ok "JetBrainsMono Nerd Font $NERD_FONTS_VERSION installed to $(tilde "$dest")"
  note "JetBrainsMono Nerd Font $NERD_FONTS_VERSION"
}
