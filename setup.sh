#!/bin/bash
cd ./dotfiles
for FILE in .
do 
  cp -R $FILE /home/$USER/
done
echo "Files copied"
echo ""

if [[ $(uname) == "Darwin" ]]; then
  brew install neovim
elif command -v apt > /dev/null; then
  sudo apt-install neovim
fi
echo ""
