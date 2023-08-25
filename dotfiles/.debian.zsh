# linuxbrew
[ -d /home/linuxbrew/.linuxbrew ] && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# android
export ANDROID_HOME=$HOME/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# go
export PATH=$PATH:/usr/local/go/bin/
export GOPATH="/usr/local/go/bin/"

# flutter
export PATH=$PATH:${HOME}/development/flutter/bin

# java with aliases
export JAVA_HOME=/usr/lib/jvm/temurin-20-jdk-amd64
export JAVA_8_HOME=/usr/lib/jvm/temurin-8-jdk-amd64
export JAVA_11_HOME=/usr/lib/jvm/temurin-11-jdk-amd64
export JAVA_17_HOME=/usr/lib/jvm/temurin-17-jdk-amd64
export JAVA_20_HOME=/usr/lib/jvm/temurin-20-jdk-amd64

alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java20='export JAVA_HOME=$JAVA_20_HOME'