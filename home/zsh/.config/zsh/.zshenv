# Read by every zsh (scripts too): repo location and environment. Keep it cheap.
# Top-level shells get here from ~/.zshenv; nested shells read it directly
# because ZDOTDIR is already exported.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Repo location, derived from where this file really lives
# (…/dotfiles/home/zsh/.config/zsh/.zshenv).
export DOTFILES="${${(%):-%x}:A:h:h:h:h:h}"

source "$ZDOTDIR/env.zsh"
