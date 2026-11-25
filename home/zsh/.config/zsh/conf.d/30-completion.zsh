# Completion: cached tool completions → compinit (once) → post plugins.

# Generate a completion file for a tool, refreshed only when the binary changes.
# (Replaces `source <(tool completion zsh)` running on every shell start.)
_cache_completion() {
  local name=$1; shift
  (( $+commands[$name] )) || return
  local out=$XDG_CACHE_HOME/zsh/completions/_$name bin=$commands[$name]
  local src=$XDG_CACHE_HOME/zsh/completions/.$name.src
  if [[ ! -s $out || $bin -nt $out || ! -r $src || $(<$src) != $bin ]]; then
    "$@" >|"$out" 2>/dev/null || { rm -f "$out" "$src"; return; }
    print -r -- "$bin" >|"$src"
  fi
}
_cache_completion doctl  doctl completion zsh
_cache_completion docker docker completion zsh
_cache_completion gh     gh completion -s zsh
_cache_completion mise   mise completion zsh
_cache_completion helm   helm completion zsh
_cache_completion kind   kind completion zsh
_cache_completion k9s    k9s completion zsh
_cache_completion uv     uv generate-shell-completion zsh

# compinit with a cached dump: full security check at most once a day.
autoload -Uz compinit
_zcompdump=$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
if [[ -n $_zcompdump(#qN.mh+24) || ! -s $_zcompdump || $ZDOTDIR/completions -nt $_zcompdump ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
for _cd in $_deferred_compdefs; do eval "compdef $_cd"; done
unset _cd _deferred_compdefs
{ [[ $_zcompdump.zwc -nt $_zcompdump ]] || zcompile "$_zcompdump" } &!
unset _zcompdump

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no                       # fzf-tab draws the menu
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*:git-checkout:*' sort false

zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza -1 --color=always --icons=auto $realpath 2>/dev/null || ls -1 $realpath'

_antidote_load plugins.post.txt

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
