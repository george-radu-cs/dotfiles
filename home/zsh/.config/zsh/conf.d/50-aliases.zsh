# Aliases. git/kubectl aliases come from the oh-my-zsh plugins (gst, gco, k, kgp…).

if (( $+commands[nvim] )); then
  alias vim=nvim vi=nvim
fi

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='ls -lah --git'
  alias la='ls -a'
  alias lt='ls --tree --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
fi

alias lg=lazygit
alias dc='docker compose'
alias reload='exec zsh'
alias path='print -rl -- $path'
alias grep='grep --color=auto'

# Java: switch the JDK for this shell (all are installed by mise).
alias java11='mise shell java@temurin-11'
alias java17='mise shell java@temurin-17'
alias java21='mise shell java@temurin-21'
alias java25='mise shell java@temurin-25'
