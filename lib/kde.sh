# shellcheck shell=bash
# KDE Plasma (Linux): Plasma settings kept in kde/.
#
# Plasma rewrites its config files by replacing them, which breaks symlinks, so
# these files are copied rather than linked:
#   dotctl kde-save   copy this machine's Plasma settings into kde/
#   dotctl kde        copy kde/ back into ~/.config (old files are backed up)

KDE_DIR="$DOTFILES/kde"

# Settings worth carrying between machines. Machine-specific state (window
# positions, recent files, caches) is deliberately left out.
KDE_FILES=(
  kdeglobals                                   # colour scheme, fonts, icons, shortcuts scheme
  kglobalshortcutsrc                           # global keyboard shortcuts
  kwinrc                                       # window manager, virtual desktops, effects
  kwinrulesrc                                  # per-window rules
  kxkbrc                                       # keyboard layouts
  kcminputrc                                   # mouse, touchpad, key repeat
  krunnerrc                                    # KRunner (the Alfred equivalent)
  kscreenlockerrc                              # lock screen
  ksmserverrc                                  # session: restore apps, logout
  plasma-localerc                              # language, formats
  dolphinrc                                    # file manager
  plasma-org.kde.plasma.desktop-appletsrc      # panels and widgets
  plasmashellrc                                # panel sizes
)

in_kde() { [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* || -n ${KDE_FULL_SESSION:-} ]]; }

# --- Plasma settings -----------------------------------------------------------

kde_save() {
  is_linux || die "kde-save runs on a Linux machine with KDE Plasma"
  in_kde || warn "this session does not look like KDE Plasma; saving whatever files exist"
  run mkdir -p "$KDE_DIR"
  local f saved=0
  for f in "${KDE_FILES[@]}"; do
    if [[ -f $XDG_CONFIG_HOME/$f ]]; then
      run cp "$XDG_CONFIG_HOME/$f" "$KDE_DIR/$f"
      saved=$((saved + 1))
    fi
  done
  ok "saved $saved Plasma settings files to $(tilde "$KDE_DIR") — review and commit them (dots)"
}

kde_apply() {
  if is_macos; then ok "KDE: nothing to do on macOS"; note "skipped (macOS)"; return 0; fi
  if [[ ! -d $KDE_DIR ]] || [[ -z $(ls -A "$KDE_DIR" 2>/dev/null) ]]; then
    info "KDE: no saved settings yet — run $DOTFILES_CMD kde-save on a configured machine"
    note "no saved settings"
    return 0
  fi
  local f applied=0
  for f in "${KDE_FILES[@]}"; do
    [[ -f $KDE_DIR/$f ]] || continue
    if [[ -f $XDG_CONFIG_HOME/$f ]] && cmp -s "$KDE_DIR/$f" "$XDG_CONFIG_HOME/$f"; then continue; fi
    [[ -e $XDG_CONFIG_HOME/$f ]] && backup "$XDG_CONFIG_HOME/$f"
    run cp "$KDE_DIR/$f" "$XDG_CONFIG_HOME/$f"
    applied=$((applied + 1))
  done
  if (( applied > 0 )); then
    ok "KDE: applied $applied settings files — log out and back in to load them"
    note "$applied settings files applied"
  else
    ok "KDE: settings already match the repo"
    note "settings up to date"
  fi
}
