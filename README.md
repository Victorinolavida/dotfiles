# tmux

To run this config you must have installed Tmux Plugin Manager (TPM) with the following command:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then run the next command to make a symbolic link to the config file:

```bash
ln -s ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

Finally, start tmux and run the following command to install the plugins:

```bash
prefix + I
```


# Zsh
To run this config you must have installed Oh My Zsh with the following command:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Then run the next command to make a symbolic link to the config file:

```bash
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
```

you also need to install the following apps:
- nvim
- bat
- fzf
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- zsh-history-substring-search
- fzf 
- eza
- ripgrep
- fd

# Neovim
To run this config you must have installed Neovim with the following command:

```bash
# For Ubuntu
sudo apt install neovim
# For MacOS
brew install neovim

```

Then run the next command to make a symbolic link to the config file:

```bash
ln -s ~/.dotfiles/nvim/init.vim ~/.config/nvim/init.vim
```


You also need to install the following plugins:
- gopls
- Node 
- Go 
- ripgrep
- fd
