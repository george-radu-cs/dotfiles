# Linux only (Arch, Fedora, Debian).

alias open='xdg-open'
alias sc='systemctl'
alias scu='systemctl --user'
alias jf='journalctl -f'

# pbcopy/pbpaste muscle memory (Wayland first, then X11).
if (( $+commands[wl-copy] )); then
  alias pbcopy='wl-copy' pbpaste='wl-paste --no-newline'
elif (( $+commands[xclip] )); then
  alias pbcopy='xclip -selection clipboard' pbpaste='xclip -selection clipboard -o'
fi
