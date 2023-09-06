# homebrew
export PATH=$PATH:/opt/homebrew/bin
export PATH=$PATH:/opt/homebrew/sbin

# android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# go
export GOPATH="${HOME}/go"
export PATH=$PATH:${HOME}/go/bin/

# flutter
export PATH=$PATH:${HOME}/development/flutter/bin

# java with aliases
export JAVA_HOME=$(/usr/libexec/java_home)
export JAVA_8_HOME=$(/usr/libexec/java_home -v 1.8)
export JAVA_11_HOME=$(/usr/libexec/java_home -v 11)
export JAVA_17_HOME=$(/usr/libexec/java_home -v 17)
export JAVA_20_HOME=$(/usr/libexec/java_home -v 20)

alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java20='export JAVA_HOME=$JAVA_20_HOME'
