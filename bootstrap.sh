#!/usr/bin/env bash
# shellcheck disable=SC2154  # colour variables come from lib/common.sh
# Set up a machine from this repo. `./bootstrap.sh` shows help; `./bootstrap.sh install`
# runs packages → links → toolchains → docker → fonts → shell. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

for lib in common link packages toolchains latex docker fonts shell kde maintenance; do
  # shellcheck source=/dev/null
  source "$DOTFILES/lib/$lib.sh"
done

usage() {
  cat <<EOF
${_c_bold}Usage:${_c_reset} ./bootstrap.sh <command> [options]

Set up this machine from the repo. Running without a command shows this help.

${_c_bold}Setup:${_c_reset}
  install        run every step below, in order (new machine, or to re-sync)
  packages       system packages: Brewfile / pacman / dnf / apt, and mise
  link           symlink home/* into \$HOME (files in the way are backed up)
  toolchains     mise tools (Java, Node, Bun, Python, uv, IPython, …), Rust, LaTeX
  docker         Docker Engine (Linux) / check Docker Desktop (macOS)
  fonts          JetBrainsMono Nerd Font
  shell          login shell, zsh/tmux/Neovim plugins, theme
  kde            Linux: KDE Plasma settings saved in kde/ (see kde-save)
                 Steps can be combined: ./bootstrap.sh link shell

${_c_bold}Maintenance:${_c_reset}
  doctor         health report: links, packages, toolchains, Neovim, LaTeX, Docker
  update         upgrade everything: packages, mise, Rust, zsh/tmux/Neovim plugins
  prune          list what is installed but no longer managed (-y removes it)
  kde-save       Linux: save this machine's KDE Plasma settings into kde/

${_c_bold}Backups:${_c_reset}
  backup         copy the current config and shell history, change nothing
  clean          move leftovers of an old setup (zinit, p10k, …) into a backup
  backups        list backups
  restore [NAME] undo the newest backup, or the one named NAME
  check          report missing or broken links
  unlink         remove every link this repo created

${_c_bold}Options:${_c_reset}
  -n, --dry-run  print what would happen, change nothing
      --extra    with packages/install on macOS: also install Brewfile.extra
  -y, --yes      with prune: remove the listed items
  -h, --help     show this help; with a command, help for that command

${_c_bold}Examples:${_c_reset}
  ./bootstrap.sh install -n      preview a full install
  ./bootstrap.sh backup          snapshot first
  ./bootstrap.sh install         set everything up
  ./bootstrap.sh link            re-link after adding a config
  ./bootstrap.sh doctor          check that everything is healthy
  ./bootstrap.sh update          upgrade everything
  ./bootstrap.sh restore         undo the last change
  ./bootstrap.sh help restore    details for one command
EOF
}

ALL_STEPS=(packages link toolchains docker fonts shell kde)
COMMANDS=(install "${ALL_STEPS[@]}" doctor update prune kde-save backup clean backups restore check unlink help)

# Closest command name (edit distance ≤ 2, or a prefix), for "did you mean".
suggest() {
  printf '%s\n' "${COMMANDS[@]}" | awk -v w="$1" '
    function lev(a, b,   i, j, la, lb, d, c) {
      la = length(a); lb = length(b)
      for (i = 0; i <= la; i++) d[i, 0] = i
      for (j = 0; j <= lb; j++) d[0, j] = j
      for (i = 1; i <= la; i++) for (j = 1; j <= lb; j++) {
        c = substr(a, i, 1) != substr(b, j, 1)
        d[i, j] = d[i - 1, j] + 1
        if (d[i, j - 1] + 1 < d[i, j]) d[i, j] = d[i, j - 1] + 1
        if (d[i - 1, j - 1] + c < d[i, j]) d[i, j] = d[i - 1, j - 1] + c
      }
      return d[la, lb]
    }
    { s = lev(w, $0); if (best == "" || s < bs) { best = $0; bs = s } }
    END { if (bs <= 2 || index(best, w) == 1) print best }'
}

# Detailed help for one command: ./bootstrap.sh help <command> or <command> --help
command_help() {
  local cmd=$1 text
  case $cmd in
    install) text="Run every setup step in order: packages, link, toolchains, docker, fonts, shell.
Use it on a new machine, or again later to bring a machine back in line with the
repo. Steps that have nothing to do finish immediately.

  ./bootstrap.sh install -n        preview, change nothing
  ./bootstrap.sh install --extra   also install packages/Brewfile.extra (macOS)" ;;
    packages) text="Install system packages. Installed packages are never upgraded.

  macOS   Xcode Command Line Tools, Homebrew, packages/Brewfile
          (--extra adds packages/Brewfile.extra)
  Linux   packages/arch.txt, fedora.txt or debian.txt, the WezTerm repository,
          and mise" ;;
    link) text="Symlink every package in home/ into \$HOME with GNU Stow.

Anything already in the way is moved to ~/.dotfiles-backup/<date>/ (undo with
'restore'). An existing ~/.gitconfig is also copied to the untracked
~/.config/git/config.local so machine-specific git settings survive." ;;
    toolchains) text="Install language toolchains, only what is missing.

  mise     every language and CLI tool in ~/.config/mise/config.toml, the same
           on every OS (Java, Node, Python, Go, Flutter, Neovim, fzf, …)
  rustup   official installer, stable toolchain, clippy, rustfmt, rust-analyzer
  LaTeX    Perl modules for latexindent; on macOS, Skim set up to jump back to
           Neovim and a working biber on Apple Silicon (TeX Live itself comes
           from the packages step)" ;;
    docker) text="  macOS   checks that Docker Desktop is installed (it comes from the Brewfile)
  Linux   adds Docker's repository (Fedora, Debian), installs the engine with
          Compose and Buildx, writes /etc/docker/daemon.json, enables the
          service and adds you to the docker group (log out and in afterwards)" ;;
    fonts) text="  macOS   nothing to do: the Brewfile installs JetBrainsMono Nerd Font
  Linux   downloads a pinned JetBrainsMono Nerd Font release into
          ~/.local/share/fonts and refreshes the font cache" ;;
    shell) text="Finish the shell setup: make zsh the login shell, carry ~/.zsh_history over
to ~/.local/state/zsh/history, install antidote and the tmux plugins, restore
Neovim plugins from lazy-lock.json, and apply the default theme if none is set." ;;
    backup) text="Copy everything this repo manages (plus shell history) to
~/.dotfiles-backup/<date>/. Nothing is changed. Linked files are stored with
their real contents. Bring a snapshot back with: ./bootstrap.sh restore <name>" ;;
    clean) text="Move leftovers of an old setup (zinit, ~/.tmux, p10k caches, .zcompdump files,
nvim.bak, neofetch config) into ~/.dotfiles-backup/<date>/. Undo with 'restore'." ;;
    backups) text="List the backups in ~/.dotfiles-backup that 'restore' can bring back." ;;
    restore) text="Undo the newest backup, or the one named: ./bootstrap.sh restore <name>

Removes this repo's links, deletes files the bootstrap created, and moves the
backed-up files back. Whatever is in the way is backed up first, so a restore
can itself be undone. List backups with: ./bootstrap.sh backups" ;;
    doctor) text="Read-only health report, with a fix for every problem it finds:
links, login shell and zsh startup time, missing or outdated packages and mise
tools, Rust, several copies of the same tool on PATH, Neovim startup warnings
and broken Mason tools, LaTeX (biber, latexindent) and Docker.
Exits with 1 when something is broken." ;;
    update) text="Upgrade everything the repo manages, one step after another:
  system     Homebrew (macOS) or pacman / dnf / apt (Linux)
  mise       all tools, and mise itself on Linux
  rustup     Rust stable
  plugins    zsh (antidote), tmux (tpm), Neovim (lazy.nvim, then treesitter
             parsers, then Mason tools)
  TeX Live   tlmgr on macOS (asks for your password)
Commit lazy-lock.json afterwards so every machine uses the same plugins." ;;
    prune) text="List what is installed but no longer managed by the repo:
Homebrew packages in neither Brewfile (macOS) and mise tool versions no config
uses. Nothing is removed unless you add -y:  ./bootstrap.sh prune -y" ;;
    kde) text="Linux with KDE Plasma: copy the settings saved in kde/ back into ~/.config
(shortcuts, window manager, keyboard and mouse, theme and fonts, panels).
Files that differ are backed up first (undo with 'restore'). Log out and back
in afterwards. Does nothing on macOS or before anything was saved." ;;
    kde-save) text="Linux with KDE Plasma: copy this machine's Plasma settings into kde/ so the
'kde' step can apply them on other machines. The files are copied, not linked,
because Plasma replaces its config files when it saves. Review the result and
commit it with 'dots'." ;;
    check) text="Report every file from home/ that is not linked into \$HOME, or links elsewhere.
Exits with 1 if something is missing." ;;
    unlink) text="Remove every symlink this repo created. Backups are not touched; use 'restore'
to bring old files back." ;;
    help) text="Show the overview, or detailed help for one command: ./bootstrap.sh help <command>" ;;
    *) usage_error "unknown command '$cmd'" "$(suggest "$cmd")" ;;
  esac
  printf '%s./bootstrap.sh %s%s\n\n%s\n' "$_c_bold" "$cmd" "$_c_reset" "$text"
}

# Wrong command or option: short message on stderr, exit 2 (usage error).
usage_error() {
  printf '%s✗ %s%s\n' "$_c_red" "$1" "$_c_reset" >&2
  [[ -n ${2:-} ]] && printf "  Did you mean '%s'?\n" "$2" >&2
  printf '  Run ./bootstrap.sh --help to see all commands.\n' >&2
  exit 2
}
STEPS=()
MODE=""
CMD=""          # first command word, for `<command> --help`
WANT_HELP=0
while [[ $# -gt 0 ]]; do
  case $1 in
    install|packages|link|toolchains|docker|fonts|shell|kde|kde-save|doctor|update|prune|check|unlink|clean|backup|backups|restore)
      [[ -z $CMD ]] && CMD=$1 ;;
  esac
  case $1 in
    install)                     MODE="install" ;;
    packages|link|toolchains|docker|fonts|shell|kde) MODE=install; STEPS+=("$1") ;;
    doctor)                      MODE="doctor" ;;
    update)                      MODE="update" ;;
    prune)                       MODE="prune" ;;
    kde-save)                    MODE="kde-save" ;;
    check|--check)               MODE="check" ;;
    unlink|--unlink)             MODE="unlink" ;;
    clean|--clean)               MODE="clean" ;;
    backup|--backup)             MODE="backup" ;;
    backups|--backups)           MODE="backups" ;;
    restore|--restore)           MODE="restore"
                                 if [[ ${2:-} && $2 != -* ]]; then RESTORE_FROM=$2; shift; fi ;;
    -n|--dry-run)                DRY_RUN=1 ;;
    -y|--yes)                    ASSUME_YES=1 ;;   # prune: actually remove
    --extra)                     WITH_EXTRA=1 ;;
    -h|--help)                   WANT_HELP=1 ;;
    help)                        if [[ -n ${2:-} && $2 != -* ]]; then command_help "$2"; else usage; fi; exit 0 ;;
    -*) usage_error "unknown option '$1'" ;;
    *)  usage_error "unknown command '$1'" "$(suggest "$1")" ;;
  esac
  shift
done
if [[ $WANT_HELP == 1 ]]; then
  if [[ -n $CMD ]]; then command_help "$CMD"; else usage; fi
  exit 0
fi
[[ -z $MODE ]] && { usage; exit 0; }
export DRY_RUN ASSUME_YES WITH_EXTRA

detect_os
printf '%sdotfiles%s · %s · %s%s\n' "$_c_bold" "$_c_reset" "$(os_pretty)" "$(tilde "$DOTFILES")" \
  "$([[ $DRY_RUN == 1 ]] && printf '  %s(dry run: nothing will change)%s' "$_c_yellow" "$_c_reset")"

case $MODE in
  doctor)  doctor; exit $? ;;
  update)  update_all; exit 0 ;;
  prune)   prune; exit 0 ;;
  kde-save) kde_save; exit 0 ;;
  check)   check_links; exit $? ;;
  unlink)  unlink_all; exit 0 ;;
  backup)  backup_config; exit 0 ;;
  clean)   clean_legacy; info "backups: $(tilde "$BACKUP_DIR")"; exit 0 ;;
  backups)
    list=$(_list_backups | sort)
    if [[ -z $list ]]; then info "no backups in ~/.dotfiles-backup"
    else while read -r d; do info "$(basename "$d")"; done <<<"$list"; fi
    exit 0 ;;
  restore) restore_backup "${RESTORE_FROM:-}"; exit 0 ;;
esac

[[ ${#STEPS[@]} -eq 0 ]] && STEPS=("${ALL_STEPS[@]}")

if [[ $DRY_RUN != 1 && $EUID -ne 0 ]] && is_linux; then
  sudo -v || die "sudo is required for system packages"
fi

total=${#STEPS[@]} n=0 started=$SECONDS
SUMMARY=()
plan=""; for s in "${STEPS[@]}"; do plan+="${plan:+ → }$s"; done
printf '%s%s%s\n' "$_c_dim" "$plan" "$_c_reset"

for s in "${STEPS[@]}"; do
  n=$((n + 1)) t0=$SECONDS STEP_NOTE=""
  case $s in
    packages)   stage $n "$total" "Packages";   install_packages ;;
    link)       stage $n "$total" "Links";      link_all ;;
    toolchains) stage $n "$total" "Toolchains"; install_toolchains ;;
    docker)     stage $n "$total" "Docker";     install_docker ;;
    fonts)      stage $n "$total" "Fonts";      install_fonts ;;
    shell)      stage $n "$total" "Shell";      setup_shell; setup_tmux; setup_nvim; setup_theme ;;
    kde)        stage $n "$total" "KDE";        kde_apply ;;
  esac
  took=$(human_time $((SECONDS - t0)))
  printf '  %sdone in %s%s\n' "$_c_dim" "$took" "$_c_reset"
  SUMMARY+=("$(printf '%-11s%s%7s%s  %s' "$s" "$_c_dim" "$took" "$_c_reset" "$STEP_NOTE")")
done

if (( total == ${#ALL_STEPS[@]} )); then done_label="All $total steps"; elif (( total == 1 )); then done_label="1 step"; else done_label="$total steps"; fi
printf '\n%s✓ %s finished in %s%s\n' "$_c_green$_c_bold" "$done_label" "$(human_time $((SECONDS - started)))" "$_c_reset"
for line in "${SUMMARY[@]}"; do printf '  %s\n' "$line"; done
if [[ -n ${BACKUP_DIR:-} && -f $BACKUP_DIR/.manifest ]]; then
  info "replaced files are in $(tilde "$BACKUP_DIR")  (undo: ./bootstrap.sh restore)"
fi
[[ $DRY_RUN == 1 ]] || printf '\n  next: %sexec zsh%s  (or open a new terminal)\n' "$_c_bold" "$_c_reset"
