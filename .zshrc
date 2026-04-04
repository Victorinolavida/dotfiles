# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting wd)

source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR="nvim"

# Language
export LANG=en_US.UTF-8
export LC_ALL="en_US.UTF-8"

# PATH
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/tmux/scripts/:$PATH"
export PATH="$HOME/.emacs.d/bin:$PATH"

# Go
export GOPATH=$HOME/go
export PATH=$PATH:$HOME/go/bin

# fnm (cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
  FNM_PATH="$HOME/Library/Application Support/fnm"
else
  FNM_PATH="$HOME/.local/share/fnm"
fi
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# ghcup
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"

# Herd Lite (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH="$HOME/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
fi

# Docker CLI completions
if [ -d "$HOME/.docker/completions" ]; then
  fpath=($HOME/.docker/completions $fpath)
fi

# Aliases
alias ls="eza --color --icons --tree --level=1 --group-directories-first"
alias vim="nvim"
alias vi="nvim"
alias vimconfig="nvim ~/.config/nvim/"
alias zshconfig="nvim ~/.zshrc"
alias reloadconfig="source ~/.zshrc"
alias reloadtmux="tmux source ~/.config/tmux/tmux.conf"
alias cat="bat"
alias clear='clear && printf "\e[3J"'
alias air='$(go env GOPATH)/bin/air'
alias droplet="ssh -i ~/.ssh/id_rsa_greenligtht greenlight@137.184.184.7"
alias viclavida="ssh -t -i ~/.ssh/id_rsa_greenligtht greenlight@137.184.184.7 ./magic.sh"

# Key bindings
bindkey -s ^o "tmux-sessionizer\n"

# fzf
source <(fzf --zsh)

# Angular CLI autocompletion
if command -v ng &>/dev/null; then
  source <(ng completion script)
fi

# p10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Yazi - change directory on exit
function ya() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Kitty OS-specific key bindings
if [[ "$OSTYPE" == "darwin"* ]]; then
  export KITTY_OS_KEYS="$HOME/.config/kitty/macos-keys.conf"
else
  export KITTY_OS_KEYS="$HOME/.config/kitty/linux-keys.conf"
fi
