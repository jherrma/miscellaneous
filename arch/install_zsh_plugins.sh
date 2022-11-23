#!/bin/bash
mkdir -p ~/.zsh
cd ~/.zsh

# auto suggestion
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc

# nix plugin
git clone https://github.com/chisui/zsh-nix-shell.git
echo 'source ~/.zsh/zsh-nix-shell/nix-shell.plugin.zsh'  >> ~/.zshrc

# powerlevel10k
git clone https://github.com/romkatv/powerlevel10k.git
echo 'source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
