# shellcheck shell=bash
# Shared helpers for bootstrap and its step scripts. Sourced, never executed.

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Colours only in a real terminal; NO_COLOR (https://no-color.org) turns them off.
if [[ -t 1 && -z ${NO_COLOR:-} && ${TERM:-} != dumb ]]; then
  _c_reset=$'\e[0m' _c_bold=$'\e[1m' _c_dim=$'\e[2m' _c_blue=$'\e[34m' _c_green=$'\e[32m' _c_yellow=$'\e[33m' _c_red=$'\e[31m'
else
  _c_reset='' _c_bold='' _c_dim='' _c_blue='' _c_green='' _c_yellow='' _c_red=''
fi

step() { printf '\n%s==>%s %s%s%s\n' "$_c_blue" "$_c_reset" "$_c_bold" "$*" "$_c_reset"; }

# Section header for a step:  "[2/6] Links ─────────────────────────"
stage() {
  local cur=$1 total=$2 label=$3 head rule="" width i
  head="[$cur/$total] $label "
  width=$(tput cols 2>/dev/null || echo 72)
  (( width > 72 )) && width=72
  for ((i = ${#head}; i < width; i++)); do rule+="─"; done
  printf '\n%s%s%s%s%s\n' "$_c_bold" "$head" "$_c_dim" "$rule" "$_c_reset"
}

# One-line result of the current step, shown again in the final summary.
# Dimmed text for inline tips, e.g. ok "done   $(hint "undo with …")"
hint() { printf '%s%s%s' "$_c_dim" "$*" "$_c_reset"; }

# shellcheck disable=SC2034  # read by bootstrap.sh
note() { STEP_NOTE=$*; }

# Print names in columns that fit the terminal (dimmed, indented).
columns() {
  local width line="    " name
  width=$(tput cols 2>/dev/null || echo 100)
  for name in "$@"; do
    if (( ${#line} + ${#name} + 2 > width )); then printf '%s%s%s\n' "$_c_dim" "$line" "$_c_reset"; line="    "; fi
    line+="$name  "
  done
  [[ $line == "    " ]] || printf '%s%s%s\n' "$_c_dim" "$line" "$_c_reset"
}

# "macOS 26.6 (arm64)" / "Fedora Linux 43 (KDE Plasma Desktop Edition)"
os_pretty() {
  if [[ $DOTFILES_OS == macos ]]; then
    printf 'macOS %s (%s)' "$(sw_vers -productVersion 2>/dev/null)" "$(uname -m)"
  else
    # shellcheck disable=SC1091
    (. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-$DOTFILES_OS}")
  fi
}

# "1m 05s" / "42s"
human_time() {
  local s=$1
  if (( s >= 60 )); then printf '%dm %02ds' $((s / 60)) $((s % 60)); else printf '%ds' "$s"; fi
}
info() { printf '  %s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn() { printf '  %s!%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
die()  { printf '%s✗ %s%s\n' "$_c_red" "$*" "$_c_reset" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# /Users/me/x → ~/x for display.
tilde() { local t='~'; printf '%s' "${1/#$HOME/$t}"; }

# Run a command, or only print it in dry-run mode.
run() {
  if [[ $DRY_RUN == 1 ]]; then
    printf '  %s[dry-run]%s %s\n' "$_c_yellow" "$_c_reset" "$*"
  else
    "$@"
  fi
}

# sudo only when we are not already root (containers run as root).
as_root() {
  if [[ $EUID -eq 0 ]]; then run "$@"; else run sudo "$@"; fi
}

confirm() {
  [[ $ASSUME_YES == 1 ]] && return 0
  local reply
  read -r -p "  $* [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]]
}

# Detect the platform once. DOTFILES_OS is one of: macos arch fedora debian
detect_os() {
  [[ -n ${DOTFILES_OS:-} ]] && return 0
  if [[ $(uname -s) == Darwin ]]; then
    DOTFILES_OS=macos
  elif [[ -r /etc/os-release ]]; then
    local ID="" ID_LIKE=""
    # shellcheck disable=SC1091
    . /etc/os-release
    case " $ID $ID_LIKE " in
      *" arch "*)                  DOTFILES_OS=arch ;;
      *" fedora "*|*" rhel "*)     DOTFILES_OS=fedora ;;
      *" debian "*|*" ubuntu "*)   DOTFILES_OS=debian ;;
      *) die "Unsupported distribution: ID=$ID ID_LIKE=$ID_LIKE" ;;
    esac
  else
    die "Cannot detect operating system"
  fi
  export DOTFILES_OS
}

is_macos() { [[ $DOTFILES_OS == macos ]]; }
is_linux() { [[ $DOTFILES_OS != macos ]]; }

# Read a package list: strips comments and blank lines.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Download a URL to a file (curl preferred, wget fallback).
fetch() {
  local url=$1 out=$2
  if has curl; then run curl -fsSL --retry 3 -o "$out" "$url"
  else run wget -q -O "$out" "$url"; fi
}
