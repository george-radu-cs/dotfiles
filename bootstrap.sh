#!/usr/bin/env bash
# shellcheck disable=SC2154  # colour variables come from lib/common.sh
# Set up a machine from this repo: packages → links → toolchains → docker → fonts → shell.
# Safe to re-run; every step checks before it changes anything.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

for lib in common link packages toolchains docker fonts shell; do
  # shellcheck source=/dev/null
  source "$DOTFILES/lib/$lib.sh"
done

usage() {
  cat <<EOF
Usage: ./bootstrap.sh [options] [steps...]

Steps (default: all, in this order):
  packages     system packages (Brewfile / pacman / dnf / apt) and mise
  link         symlink home/* into \$HOME with stow (existing files are backed up)
  toolchains   mise install (java, node, bun, go, python, uv, linux CLI tools) + rustup
  docker       Docker Engine + /etc/docker/daemon.json (Linux) / Docker Desktop (macOS)
  fonts        JetBrainsMono Nerd Font
  shell        zsh as login shell, antidote, tmux plugins, neovim plugins, theme

Options:
  -n, --dry-run   print what would run, change nothing
  -y, --yes       don't ask for confirmation
      --extra     also install packages/Brewfile.extra (macOS)
      --check     report missing links, then exit
      --backup    copy the current config (everything this repo manages, plus
                  shell history) to ~/.dotfiles-backup/<date>/, then exit
      --clean     move leftovers of the old setup (zinit, p10k caches, .zcompdump…)
                  into ~/.dotfiles-backup/<date>/, then exit
      --restore [BACKUP]
                  undo link/clean: remove the links and put back what the backup
                  holds (default: the newest backup), then exit
      --backups   list backups that can be restored
      --unlink    remove all links created by this repo, then exit
  -h, --help      show this help

Examples:
  ./bootstrap.sh                  # fresh machine
  ./bootstrap.sh link             # re-link after adding files
  ./bootstrap.sh -n               # preview everything
  ./bootstrap.sh --backup         # snapshot the current config, change nothing
  ./bootstrap.sh --restore        # go back to the newest backup
EOF
}

STEPS=()
MODE=install
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    --extra)      WITH_EXTRA=1 ;;
    --check)      MODE="check" ;;
    --unlink)     MODE="unlink" ;;
    --clean)      MODE="clean" ;;
    --backup)     MODE="backup" ;;
    --backups)    MODE="backups" ;;
    --restore)    MODE="restore"
                  if [[ ${2:-} && $2 != -* ]]; then RESTORE_FROM=$2; shift; fi ;;
    -h|--help)    usage; exit 0 ;;
    packages|link|toolchains|docker|fonts|shell) STEPS+=("$1") ;;
    *) usage; die "unknown argument: $1" ;;
  esac
  shift
done
export DRY_RUN ASSUME_YES WITH_EXTRA

detect_os
printf '%sdotfiles%s · %s · %s%s\n' "$_c_bold" "$_c_reset" "$(os_pretty)" "$(tilde "$DOTFILES")" \
  "$([[ $DRY_RUN == 1 ]] && printf '  %s(dry run: nothing will change)%s' "$_c_yellow" "$_c_reset")"

case $MODE in
  check)  check_links; exit $? ;;
  unlink)  unlink_all; exit 0 ;;
  backup)  backup_config; exit 0 ;;
  clean)   clean_legacy; info "backups: $(tilde "$BACKUP_DIR")"; exit 0 ;;
  backups) _list_backups | sort | while read -r d; do info "$(basename "$d")"; done; exit 0 ;;
  restore) restore_backup "${RESTORE_FROM:-}"; exit 0 ;;
esac

[[ ${#STEPS[@]} -eq 0 ]] && STEPS=(packages link toolchains docker fonts shell)

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

printf '\n%s✓ All %d steps finished in %s%s\n' "$_c_green$_c_bold" "$total" "$(human_time $((SECONDS - started)))" "$_c_reset"
for line in "${SUMMARY[@]}"; do printf '  %s\n' "$line"; done
if [[ -n ${BACKUP_DIR:-} && -f $BACKUP_DIR/.manifest ]]; then
  info "replaced files are in $(tilde "$BACKUP_DIR")  (undo: ./bootstrap.sh --restore)"
fi
[[ $DRY_RUN == 1 ]] || printf '\n  next: %sexec zsh%s  (or open a new terminal)\n' "$_c_bold" "$_c_reset"
