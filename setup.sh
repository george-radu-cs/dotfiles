#!/bin/bash
cd ./dotfiles
for FILE in .
do 
  cp -R $FILE /home/$USER/
done
echo "Files copied"
echo ""

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "Installed vim plug"
echo ""
