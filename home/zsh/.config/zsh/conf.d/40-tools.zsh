# Tool integrations. `tool init zsh` output is cached and only regenerated when
# the tool's binary changes; that saves a subprocess per tool on every start.

_cache_eval() {
  local name=$1; shift
  (( $+commands[$name] )) || return 1
  local out=$XDG_CACHE_HOME/zsh/eval-$name.zsh
  if [[ ! -s $out || $commands[$name] -nt $out ]]; then
    "$@" >|"$out" 2>/dev/null || { rm -f "$out"; return 1; }
  fi
  source "$out"
}

# Theme (written by `theme <name>`): BAT_THEME, fzf colours, …
_theme_env="$XDG_STATE_HOME/dotfiles/theme/shell.zsh"
if [[ -r $_theme_env ]]; then source "$_theme_env"; else export BAT_THEME=gruvbox-dark; fi
unset _theme_env

# mise: java, node, bun, go, python, … (and the Linux CLI tools)
_cache_eval mise mise activate zsh

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --info=inline-right ${DOTFILES_FZF_COLORS:-}"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=auto {} 2>/dev/null'"
_cache_eval fzf fzf --zsh
# fzf --zsh binds Tab to its own completion; give Tab back to fzf-tab.
(( $+functions[enable-fzf-tab] )) && enable-fzf-tab

# zoxide: `z foo`, `zi` for interactive
_cache_eval zoxide zoxide init zsh

# prompt
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
_cache_eval starship starship init zsh
