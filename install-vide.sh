#!/bin/bash
SCRIPT_DIR=$(dirname $(realpath $0))

echo SCRIPT_DIR=$SCRIPT_DIR

# Backup original files
[ -L $HOME/.vim ] || mv $HOME/.vim $HOME/.vim.bkp
[ -L $HOME/.vimrc ] || mv $HOME/.vimrc $HOME/.vimrc.bkp

# Create symbolic links to vim most important file/dir
[ -L $HOME/.vim ] && rm $HOME/.vim
[ -L $HOME/.vimrc ] && rm $HOME/.vimrc
ln -sf $SCRIPT_DIR/install/dot-vim $HOME/.vim
ln -sf $SCRIPT_DIR/install/dot-vimrc $HOME/.vimrc

# Create symbolic links to scripts that shall be available on the path
ln -sf  $SCRIPT_DIR/install/scripts/* $HOME/bin/

# Find out in what shell it is running and install 
# If we detect that there is a dassh_tools_dir, we install there
for WS in ".zshrc" ".bashrc"
do
if [ -e "$HOME/$WS" ]; then
  echo "Installing for $WS"
  grep "source ~/.vim/vide-shell-functions.sh" "$HOME/$WS" || printf "source ~/.vim/vide-shell-functions.sh\n" >> "$HOME/$WS"
  grep VI_SERVER "$HOME/$WS" || printf "export VI_SERVER=\"vide\"\n" >> "$HOME/$WS"
else
  echo "ERROR: Don't know where to install vide main functions."
fi
done
