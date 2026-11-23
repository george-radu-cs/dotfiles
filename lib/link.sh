# shellcheck shell=bash
# Symlink packages from home/ into $HOME with GNU Stow.
#
# Each directory in home/ is a stow package that mirrors $HOME. Anything already
# sitting where a link should go is moved to $BACKUP_DIR first, never deleted.
# Every move/creation is recorded in $BACKUP_DIR/.manifest so --restore can undo it.

# One folder per run; a suffix keeps two runs in the same second apart.
if [[ -z ${BACKUP_DIR:-} ]]; then
  BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  _n=2
  while [[ -e $BACKUP_DIR ]]; do BACKUP_DIR="${BACKUP_DIR%-[0-9]}-$_n"; _n=$((_n + 1)); done
  unset _n
fi

# Packages linked everywhere. Order does not matter.
LINK_PACKAGES=(zsh git nvim tmux wezterm starship mise lazygit fastfetch vim ideavim bin)

# Pre-1.0 zsh setup kept everything in $HOME. With ZDOTDIR these are dead files,
# so move them out of the way to avoid confusion.
LEGACY_FILES=(
  .zshrc .zprofile .zlogin .p10k.zsh .macos.zsh .brew.zsh .debian.zsh
  .systemd.zsh .kubectl.zsh .freebsd.zsh .fzf.zsh
)

# Leftovers of the old setup that nothing uses anymore (`--clean`). Globs, relative
# to $HOME. They are moved to a backup folder like everything else, not deleted.
CLEAN_PATHS=(
  '.zcompdump*' .p10k.zsh.bak .save_p10k.zsh .zprofile.bak .zprofile.pysave
  .fzf.bash .iterm2_shell_integration.zsh
  .local/share/zinit .tmux .config/nvim.bak .config/neofetch
  '.cache/p10k-*' .cache/zinit
)

# Portable `realpath` (macOS ships no readlink -f before 13): resolves parent
# directory links and then follows the final component's symlink chain.
_resolve() {
  local path=$1 dir base link
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    dir=$(cd "$(dirname "$path")" 2>/dev/null && pwd -P) || { printf '%s\n' "$path"; return; }
    base=$(basename "$path")
    path="$dir/$base"
    [[ -L $path ]] || break
    link=$(readlink "$path")
    [[ $link == /* ]] && path=$link || path="$dir/$link"
  done
  printf '%s\n' "$path"
}

_manifest() {
  [[ $DRY_RUN == 1 ]] && return 0
  mkdir -p "$BACKUP_DIR"
  printf '%s\t%s\n' "$1" "$2" >>"$BACKUP_DIR/.manifest"
}

backup() {
  local target=$1 rel=${1#"$HOME"/}
  run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  run mv "$target" "$BACKUP_DIR/$rel"
  _manifest moved "$rel"
  BACKED_UP=$(( ${BACKED_UP:-0} + 1 ))
  warn "backed up ~/$rel → $(tilde "$BACKUP_DIR")/$rel"
}

# Is $1 a symlink that already resolves into this repo?
_links_into_repo() {
  [[ -L $1 ]] || return 1
  [[ $(_resolve "$1") == "$(cd "$DOTFILES" && pwd -P)"/* ]]
}

# Move anything that would block stow. Stow "folds" a package directory into a
# single symlink when the target directory does not exist yet (e.g.
# ~/.config/nvim → repo), so we check the top-level entry of every package path
# first and only descend when it is a real directory we need to merge into.
_clear_conflicts() {
  local pkg=$1 src="$DOTFILES/home/$1" entry rel target
  while IFS= read -r -d '' entry; do
    rel=${entry#"$src"/}
    target="$HOME/$rel"
    if _links_into_repo "$target"; then
      continue
    elif [[ -L $target ]]; then
      backup "$target"                       # foreign or dangling symlink
    elif [[ -d $target && -d $entry ]]; then
      # Shared parents like ~/.config or ~/.local/bin: keep, look inside.
      if [[ " .config .local .local/bin .local/share " == *" $rel "* ]]; then
        _clear_conflicts_in "$pkg" "$rel"
      else
        backup "$target"                     # e.g. an old ~/.config/nvim
      fi
    elif [[ -e $target ]]; then
      backup "$target"
    fi
  done < <(find "$src" -mindepth 1 -maxdepth 1 ! -name .DS_Store -print0)
}

_clear_conflicts_in() {
  local pkg=$1 src="$DOTFILES/home/$1/$2" entry rel target
  while IFS= read -r -d '' entry; do
    rel=${entry#"$DOTFILES/home/$pkg"/}
    target="$HOME/$rel"
    if _links_into_repo "$target"; then
      continue
    elif [[ -d $target && ! -L $target && -d $entry && " .config .local .local/bin .local/share " == *" $rel "* ]]; then
      _clear_conflicts_in "$pkg" "$rel"
    elif [[ -e $target || -L $target ]]; then
      backup "$target"
    fi
  done < <(find "$src" -mindepth 1 -maxdepth 1 ! -name .DS_Store -print0)
}

link_package() {
  local pkg=$1
  [[ -d $DOTFILES/home/$pkg ]] || die "unknown package: $pkg"
  _clear_conflicts "$pkg"
  run stow --dir "$DOTFILES/home" --target "$HOME" --ignore='\.DS_Store' --restow "$pkg"
}

unlink_package() {
  run stow --dir "$DOTFILES/home" --target "$HOME" --ignore='\.DS_Store' --delete "$1"
  ok "unlinked $1"
}

link_all() {
  if ! has stow; then
    [[ $DRY_RUN == 1 ]] || die "GNU stow is not installed (run the packages step first)"
    warn "stow not installed yet (dry run) — showing what would be linked"
  fi
  # Make sure shared parents exist so stow folds at the app level, not at
  # ~/.config or ~/.local as a whole.
  run mkdir -p "$XDG_CONFIG_HOME" "$HOME/.local/bin" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

  local f
  for f in "${LEGACY_FILES[@]}"; do
    if [[ -e $HOME/$f || -L $HOME/$f ]] && ! _links_into_repo "$HOME/$f"; then
      backup "$HOME/$f"
    fi
  done
  # An old ~/.gitconfig wins over ~/.config/git/config. Keep its contents as the
  # untracked local override so work includeIf rules etc. survive.
  if [[ -f $HOME/.gitconfig && ! -L $HOME/.gitconfig ]]; then
    if [[ ! -e $XDG_CONFIG_HOME/git/config.local ]]; then
      run mkdir -p "$BACKUP_DIR"
      run cp "$HOME/.gitconfig" "$BACKUP_DIR/.gitconfig"
      _pending_git_local="$BACKUP_DIR/.gitconfig"
    fi
    backup "$HOME/.gitconfig"
  fi

  local pkg
  for pkg in "${LINK_PACKAGES[@]}"; do link_package "$pkg"; done
  ok "linked ${#LINK_PACKAGES[@]} packages into $(tilde "$HOME")"
  columns "${LINK_PACKAGES[@]}"
  if (( ${BACKED_UP:-0} > 0 )); then
    note "${#LINK_PACKAGES[@]} packages linked · ${BACKED_UP} old files backed up"
  else
    note "${#LINK_PACKAGES[@]} packages linked"
  fi

  if [[ -n ${_pending_git_local:-} ]]; then
    run cp "$_pending_git_local" "$XDG_CONFIG_HOME/git/config.local"
    _manifest created "$XDG_CONFIG_HOME/git/config.local"
    warn "old ~/.gitconfig copied to ~/.config/git/config.local (untracked) — trim what the repo config already sets"
  fi
}

unlink_all() {
  has stow || die "GNU stow is not installed"
  local pkg
  for pkg in "${LINK_PACKAGES[@]}"; do unlink_package "$pkg"; done
}

# Move old-setup leftovers (CLEAN_PATHS) into a backup folder.
clean_legacy() {
  local pattern path found=0
  for pattern in "${CLEAN_PATHS[@]}"; do
    # shellcheck disable=SC2206  # intentional glob expansion
    local matches=($HOME/$pattern)
    for path in "${matches[@]}"; do
      [[ -e $path || -L $path ]] || continue   # unmatched glob stays literal
      _links_into_repo "$path" && continue
      backup "$path"; found=1
    done
  done
  [[ $found == 1 ]] || ok "nothing to clean"
}

_list_backups() {
  local d
  for d in "$HOME"/.dotfiles-backup/*/; do
    [[ -f $d.manifest ]] && printf '%s\n' "${d%/}"
  done
  return 0
}

# $HOME-relative paths this repo manages: each package's top-level entries
# (descending into shared parents like ~/.config), old-setup files, history.
_pkg_paths() {
  local src=$1 prefix=$2 entry rel
  while IFS= read -r -d '' entry; do
    rel="$prefix$(basename "$entry")"
    if [[ -d $entry && " .config .local .local/bin .local/share " == *" $rel "* ]]; then
      _pkg_paths "$entry" "$rel/"
    else
      printf '%s\n' "$rel"
    fi
  done < <(find "$src" -mindepth 1 -maxdepth 1 ! -name .DS_Store -print0)
}

_managed_paths() {
  local pkg
  for pkg in "${LINK_PACKAGES[@]}"; do _pkg_paths "$DOTFILES/home/$pkg" ""; done
  printf '%s\n' "${LEGACY_FILES[@]}" .gitconfig .zsh_history .local/state/zsh/history
}

# Snapshot the current config without touching it. Linked files are stored with
# their real contents, so the snapshot stays valid even if the repo changes.
backup_config() {
  local rel src count=0
  while IFS= read -r rel; do
    src="$HOME/$rel"
    [[ -e $src ]] || continue                 # missing or dangling link
    run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    run cp -RL "$src" "$BACKUP_DIR/$rel" || { warn "could not copy ~/$rel"; continue; }
    _manifest copied "$rel"
    count=$((count + 1))
  done < <(_managed_paths | sort -u)
  ok "backed up $count paths → $(tilde "$BACKUP_DIR")"
}

# Undo `link` / `--clean`, or go back to a `--backup` snapshot: remove the links,
# delete files bootstrap created, and put back everything in the manifest.
# Whatever is in the way is itself backed up first, so a restore can be undone.
restore_backup() {
  local dir=${1:-}
  if [[ -z $dir ]]; then
    dir=$(_list_backups | sort | tail -n 1)
    [[ -n $dir ]] || die "no backups with a manifest in ~/.dotfiles-backup"
  fi
  [[ $dir == /* ]] || dir="$HOME/.dotfiles-backup/$dir"
  [[ -f $dir/.manifest ]] || die "no manifest in $(tilde "$dir") (already restored?)"

  info "restoring from $(tilde "$dir")"
  unlink_all

  local kind rel src dst
  # newest entries first, so nested moves unwind in the right order
  while IFS=$'\t' read -r kind rel; do
    case $kind in
      created)
        if [[ -e $rel ]]; then run rm -f "$rel"; ok "removed $(tilde "$rel")"; fi ;;
      moved)
        src="$dir/$rel" dst="$HOME/$rel"
        [[ -e $src || -L $src ]] || { warn "missing in backup: $rel"; continue; }
        if [[ -L $dst ]] && _links_into_repo "$dst"; then run rm "$dst"; fi
        if [[ -d $dst && ! -L $dst ]]; then rmdir "$dst" 2>/dev/null || true; fi
        if [[ -e $dst || -L $dst ]]; then warn "skipped ~/$rel: something new is there"; continue; fi
        run mkdir -p "$(dirname "$dst")"
        run mv "$src" "$dst"
        ok "restored ~/$rel" ;;
      copied)
        src="$dir/$rel" dst="$HOME/$rel"
        [[ -e $src ]] || { warn "missing in backup: $rel"; continue; }
        if [[ -L $dst ]] && _links_into_repo "$dst"; then run rm "$dst"; fi
        if [[ -e $dst || -L $dst ]]; then backup "$dst"; fi
        run mkdir -p "$(dirname "$dst")"
        run cp -RP "$src" "$dst"
        ok "restored ~/$rel" ;;
    esac
  done < <(awk '{ l[NR] = $0 } END { for (i = NR; i > 0; i--) print l[i] }' "$dir/.manifest")

  # Snapshots (--backup) stay restorable; moved-out backups are now empty.
  if [[ $DRY_RUN != 1 ]] && ! grep -q '^copied' "$dir/.manifest"; then
    mv "$dir/.manifest" "$dir/.manifest.restored"
  fi
  ok "restore complete (backup folder kept: $(tilde "$dir"))"
  [[ -f $BACKUP_DIR/.manifest ]] && info "what was replaced is in $(tilde "$BACKUP_DIR") (--restore undoes this)"
  return 0
}

# Report files whose links are missing or point somewhere else.
check_links() {
  local pkg src file rel bad=0
  for pkg in "${LINK_PACKAGES[@]}"; do
    src="$DOTFILES/home/$pkg"
    while IFS= read -r -d '' file; do
      rel=${file#"$src"/}
      if [[ $(_resolve "$HOME/$rel") != "$(_resolve "$file")" ]]; then
        warn "not linked: ~/$rel ($pkg)"; bad=1
      fi
    done < <(find "$src" -type f ! -name .DS_Store -print0)
  done
  [[ $bad == 0 ]] && ok "all packages linked"
  return $bad
}
