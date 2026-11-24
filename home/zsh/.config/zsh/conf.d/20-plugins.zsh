# Plugins via antidote. The plugin lists compile into static files that are
# only rebuilt when a list changes, so normal startup just sources them.
#
#   plugins.txt       loaded before compinit (fpath, oh-my-zsh pieces, vi-mode)
#   plugins.post.txt  loaded after compinit (fzf-tab, autosuggestions, highlighting)
#
# Update plugins: `antidote update`, then `exec zsh`.

export ANTIDOTE_HOME="$XDG_CACHE_HOME/antidote"
_antidote_dir="$XDG_DATA_HOME/antidote"

# oh-my-zsh plugins expect these; we load single plugins, not the framework.
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh/omz"
mkdir -p "$ZSH_CACHE_DIR/completions" 2>/dev/null
fpath=(
  "$ZDOTDIR/completions"              # completions shipped with this repo
  "$ZSH_CACHE_DIR/completions"
  "$XDG_CACHE_HOME/zsh/completions"
  $HOME/.docker/completions(N-/)     # Docker Desktop (macOS)
  $fpath
)

# Plugins may call compdef before compinit exists; queue those calls and
# replay them after compinit (conf.d/30-completion.zsh).
typeset -ga _deferred_compdefs
compdef() { _deferred_compdefs+=("${(j: :)${(q)@}}") }

# antidote `conditional:` helpers (see plugins*.txt)
_has_aws() { (( $+commands[aws] )) }

# The aws plugin would add $(aws_prompt_info) to RPROMPT; starship covers it.
SHOW_AWS_PROMPT=false

# zsh-vi-mode: load in "sourcing" mode so later key bindings (fzf, autosuggest)
# are not overwritten when it initialises.
ZVM_INIT_MODE=sourcing

if [[ ! -d $_antidote_dir ]]; then
  print -P "%F{yellow}installing antidote…%f"
  git clone --depth=1 --quiet https://github.com/mattmc3/antidote.git "$_antidote_dir"
fi

# Build (if stale) and source a static bundle for one plugin list.
_antidote_load() {
  local list=$ZDOTDIR/$1 out=$XDG_CACHE_HOME/zsh/${1:r}.zsh
  if [[ ! $out -nt $list ]]; then
    (( $+functions[antidote] )) || source "$_antidote_dir/antidote.zsh"
    antidote bundle <"$list" >|"$out"
  fi
  source "$out"
}

_antidote_load plugins.txt
