# ~/.zshenv: the only zsh file in $HOME. It points zsh at ~/.config/zsh and hands
# over to $ZDOTDIR/.zshenv, which nested shells (ZDOTDIR already set) read directly.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
source "$ZDOTDIR/.zshenv"
