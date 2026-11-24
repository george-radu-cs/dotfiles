# Interactive zsh. Modules in conf.d/ load in name order, then the OS file,
# then the untracked local.zsh for machine-specific bits and secrets.
#
# Profile startup:  ZPROF=1 zsh -i -c exit
# Time startup:     zbench

[[ -n $ZPROF ]] && zmodload zsh/zprof

# Greeting only in a top-level terminal, not in tmux panes, nvim or scripts.
if [[ ${DOTFILES_GREETING:-1} == 1 && -z $TMUX && -z $NVIM && $SHLVL -le 1 ]] && (( $+commands[fastfetch] )); then
  fastfetch
fi

mkdir -p "$XDG_CACHE_HOME/zsh/completions" "$XDG_STATE_HOME/zsh" 2>/dev/null

for _f in "$ZDOTDIR"/conf.d/*.zsh(N); do source "$_f"; done

if [[ $OSTYPE == darwin* ]]; then
  source "$ZDOTDIR/os/darwin.zsh"
else
  source "$ZDOTDIR/os/linux.zsh"
fi

[[ -r $ZDOTDIR/local.zsh ]] && source "$ZDOTDIR/local.zsh"
unset _f

[[ -n $ZPROF ]] && zprof
true
