#!/usr/bin/env bash
# shellcheck disable=SC2154  # colour variables come from lib/common.sh
# Set up a machine from this repo. `./bootstrap.sh` shows help; `./bootstrap.sh install`
# runs packages → links → toolchains → docker → fonts → shell. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

for lib in common link packages toolchains docker fonts shell; do
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
  toolchains     mise tools (Java, Node, Bun, Python, uv, IPython, …) and Rust
  docker         Docker Engine (Linux) / check Docker Desktop (macOS)
  fonts          JetBrainsMono Nerd Font
  shell          login shell, zsh/tmux/Neovim plugins, theme
                 Steps can be combined: ./bootstrap.sh link shell

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
  -h, --help     show this help

${_c_bold}Examples:${_c_reset}
  ./bootstrap.sh install -n      preview a full install
  ./bootstrap.sh backup          snapshot first
  ./bootstrap.sh install         set everything up
  ./bootstrap.sh link            re-link after adding a config
  ./bootstrap.sh restore         undo the last change
EOF
}

ALL_STEPS=(packages link toolchains docker fonts shell)
COMMANDS=(install "${ALL_STEPS[@]}" backup clean backups restore check unlink help)

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

# Wrong command or option: short message on stderr, exit 2 (usage error).
usage_error() {
  printf '%s✗ %s%s\n' "$_c_red" "$1" "$_c_reset" >&2
  [[ -n ${2:-} ]] && printf "  Did you mean '%s'?\n" "$2" >&2
  printf '  Run ./bootstrap.sh --help to see all commands.\n' >&2
  exit 2
}
STEPS=()
MODE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    install)                     MODE="install" ;;
    packages|link|toolchains|docker|fonts|shell) MODE=install; STEPS+=("$1") ;;
    check|--check)               MODE="check" ;;
    unlink|--unlink)             MODE="unlink" ;;
    clean|--clean)               MODE="clean" ;;
    backup|--backup)             MODE="backup" ;;
    backups|--backups)           MODE="backups" ;;
    restore|--restore)           MODE="restore"
                                 if [[ ${2:-} && $2 != -* ]]; then RESTORE_FROM=$2; shift; fi ;;
    -n|--dry-run)                DRY_RUN=1 ;;
    -y|--yes)                    ASSUME_YES=1 ;;   # accepted for compatibility; nothing prompts
    --extra)                     WITH_EXTRA=1 ;;
    -h|--help|help)              usage; exit 0 ;;
    -*) usage_error "unknown option '$1'" ;;
    *)  usage_error "unknown command '$1'" "$(suggest "$1")" ;;
  esac
  shift
done
[[ -z $MODE ]] && { usage; exit 0; }
export DRY_RUN ASSUME_YES WITH_EXTRA

detect_os
printf '%sdotfiles%s · %s · %s%s\n' "$_c_bold" "$_c_reset" "$(os_pretty)" "$(tilde "$DOTFILES")" \
  "$([[ $DRY_RUN == 1 ]] && printf '  %s(dry run: nothing will change)%s' "$_c_yellow" "$_c_reset")"

case $MODE in
  check)  check_links; exit $? ;;
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
