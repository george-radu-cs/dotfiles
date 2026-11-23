# ~/.zshenv — the only zsh file in $HOME. Read by every zsh (scripts too), so
# keep it cheap: XDG dirs, ZDOTDIR, and PATH. Everything else is in $ZDOTDIR.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Repo location, derived from where this symlink points (…/dotfiles/home/zsh/.zshenv).
export DOTFILES="${${(%):-%x}:A:h:h:h}"

source "$ZDOTDIR/env.zsh"
