# Login shells: macOS's /etc/zprofile has just run path_helper, which moves
# system paths in front of ours. Re-apply our PATH order.
source "$ZDOTDIR/env.zsh"

# Machine-specific login settings (untracked).
[[ -r $ZDOTDIR/local.zprofile ]] && source "$ZDOTDIR/local.zprofile"
