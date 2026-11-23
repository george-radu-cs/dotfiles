# macOS only.

# Let builds find Homebrew libraries.
export CPPFLAGS="-I$HOMEBREW_PREFIX/include"
export LDFLAGS="-L$HOMEBREW_PREFIX/lib"
export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/lib/pkgconfig"

alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
