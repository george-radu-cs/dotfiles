# Shell options and history.

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt extended_history       # timestamps in history
setopt share_history          # share between running shells
setopt hist_ignore_all_dups   # drop older duplicate
setopt hist_ignore_space      # " cmd" is not recorded
setopt hist_reduce_blanks
setopt hist_verify            # !! expands into the buffer instead of running

setopt auto_cd                # `dir` == `cd dir`
setopt auto_pushd pushd_ignore_dups pushd_silent
setopt interactive_comments
setopt no_beep
setopt extended_glob

WORDCHARS=${WORDCHARS//[\/]}  # ctrl-w stops at /
