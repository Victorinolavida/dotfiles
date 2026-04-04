#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[install]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; }

# ── OS Detection ────────────────────────────────────────────────────────────
is_mac()   { [[ "$OSTYPE" == "darwin"* ]]; }
is_linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }

has() { command -v "$1" &>/dev/null; }

# ── Package manager ─────────────────────────────────────────────────────────
pkg_install() {
  if is_mac; then
    brew install "$@"
  elif is_linux; then
    sudo apt-get install -y "$@"
  fi
}

setup_package_manager() {
  if is_mac; then
    if ! has brew; then
      log "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      success "Homebrew already installed"
    fi
  elif is_linux; then
    log "Updating apt..."
    sudo apt-get update -qq
  fi
}

# ── Core tools ───────────────────────────────────────────────────────────────
install_core() {
  log "Installing core tools (git, curl, zsh)..."
  pkg_install git curl zsh
  success "Core tools installed"
}

# ── Terminal ─────────────────────────────────────────────────────────────────
install_kitty() {
  if has kitty; then
    success "Kitty already installed"
    return
  fi
  log "Installing Kitty..."
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  success "Kitty installed"
}

# ── Editor ───────────────────────────────────────────────────────────────────
install_nvim() {
  if ! has nvim; then
    log "Installing Neovim..."
    if is_mac; then
      brew install neovim
    elif is_linux; then
      sudo snap install nvim --classic
    fi
    success "Neovim installed"
  else
    success "Neovim already installed"
  fi

  # Symlink nvim config from submodule
  local nvim_config="$CONFIG_DIR/nvim"
  if [ ! -e "$nvim_config" ]; then
    log "Initializing nvim submodule..."
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    ln -s "$DOTFILES_DIR/nvim" "$nvim_config"
    success "Nvim config linked"
  else
    success "Nvim config already exists at $nvim_config"
  fi

  # Initialize plugins (lazy.nvim)
  log "Initializing nvim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null
  success "Nvim plugins initialized"
}

# ── Shell tools ───────────────────────────────────────────────────────────────
install_shell_tools() {
  log "Installing shell tools (eza, bat, fzf, fd, zoxide, lazygit, yazi)..."

  if is_mac; then
    brew install eza bat fzf fd zoxide lazygit yazi
  elif is_linux; then
    # eza
    if ! has eza; then
      sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list
      sudo apt-get update -qq && sudo apt-get install -y eza
    fi

    # bat (Ubuntu packages it as batcat)
    if ! has bat && ! has batcat; then
      pkg_install bat
      # create alias if installed as batcat
      if has batcat && ! has bat; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
      fi
    fi

    pkg_install fzf fd-find zoxide

    # fd is installed as fdfind on Ubuntu
    if has fdfind && ! has fd; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
    fi

    # lazygit
    if ! has lazygit; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
      curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin
    fi

    # yazi (binary release)
    if ! has yazi; then
      YAZI_VERSION=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
      curl -Lo /tmp/yazi.zip \
        "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
      unzip -o /tmp/yazi.zip -d /tmp/yazi
      sudo install "/tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/yazi
      sudo install "/tmp/yazi/yazi-x86_64-unknown-linux-gnu/ya" /usr/local/bin/ya
      rm -rf /tmp/yazi /tmp/yazi.zip
    fi
  fi

  success "Shell tools installed"
}

# ── Tmux ─────────────────────────────────────────────────────────────────────
install_tmux() {
  if has tmux; then
    success "Tmux already installed"
  else
    log "Installing tmux..."
    pkg_install tmux
  fi

  # Install TPM (Tmux Plugin Manager)
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    log "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    success "TPM installed — press prefix+I inside tmux to install plugins"
  else
    success "TPM already installed"
  fi
}

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
install_omzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    success "Oh My Zsh already installed"
  else
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Powerlevel10k
  if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    log "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k"
  else
    success "Powerlevel10k already installed"
  fi

  # zsh-autosuggestions
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    success "zsh-autosuggestions already installed"
  fi

  # zsh-syntax-highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    success "zsh-syntax-highlighting already installed"
  fi

  success "Oh My Zsh + plugins installed"
}

# ── fnm (Node version manager) ───────────────────────────────────────────────
install_fnm() {
  if has fnm; then
    success "fnm already installed"
    return
  fi
  log "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash
  success "fnm installed — restart your shell then run: fnm install --lts"
}

# ── Go ────────────────────────────────────────────────────────────────────────
install_go() {
  if has go; then
    success "Go already installed"
    return
  fi
  log "Installing Go..."
  if is_mac; then
    brew install go
  elif is_linux; then
    pkg_install golang-go
  fi
  success "Go installed"
}

# ── Rust/Cargo ────────────────────────────────────────────────────────────────
install_rust() {
  if has cargo; then
    success "Rust/Cargo already installed"
    return
  fi

  # Install build dependencies required by Rust crates (e.g. yazi)
  if is_linux; then
    log "Installing Rust build dependencies..."
    pkg_install build-essential libssl-dev pkg-config
  fi

  log "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  success "Rust installed"
}

# ── Fonts ────────────────────────────────────────────────────────────────────
install_fonts() {
  log "Installing JetBrainsMono Nerd Font..."

  if is_mac; then
    brew install --cask font-jetbrains-mono-nerd-font
  elif is_linux; then
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
      success "JetBrainsMono Nerd Font already installed"
      return
    fi
    local version
    version=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
      | grep '"tag_name"' | sed 's/.*"\(v[^"]*\)".*/\1/')
    curl -Lo /tmp/JetBrainsMono.zip \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"
    mkdir -p "$font_dir"
    unzip -o /tmp/JetBrainsMono.zip -d "$font_dir"
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv "$font_dir"
  fi

  success "JetBrainsMono Nerd Font installed"
}

# ── Dotfile symlinks ──────────────────────────────────────────────────────────
setup_symlinks() {
  log "Setting up dotfile symlinks..."

  link() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"

    if [ -L "$dst" ]; then
      success "Already linked: $dst"
      return
    fi

    if [ -e "$dst" ]; then
      warn "Backing up existing $dst → ${dst}.bak"
      mv "$dst" "${dst}.bak"
    fi

    ln -s "$src" "$dst"
    success "Linked: $dst → $src"
  }

  mkdir -p "$CONFIG_DIR"

  link "kitty"   "$CONFIG_DIR/kitty"
  link "yazi"    "$CONFIG_DIR/yazi"
  link ".zshrc"  "$HOME/.zshrc"
}

# ── Help ─────────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --all          Install everything"
  echo "  --core         Core tools (git, curl, zsh)"
  echo "  --terminal     Kitty terminal"
  echo "  --editor       Neovim"
  echo "  --shell-tools  eza, bat, fzf, fd, zoxide, lazygit, yazi"
  echo "  --tmux         Tmux + TPM"
  echo "  --omzsh        Oh My Zsh + plugins + Powerlevel10k"
  echo "  --fnm          Node version manager"
  echo "  --go           Go language"
  echo "  --rust         Rust + Cargo"
  echo "  --fonts        JetBrainsMono Nerd Font"
  echo "  --symlinks     Dotfile symlinks only"
  echo "  --help         Show this help"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  if [ $# -eq 0 ]; then
    usage
    exit 0
  fi

  for arg in "$@"; do
    case "$arg" in
      --all)
        setup_package_manager
        install_core
        install_rust
        install_kitty
        install_nvim
        install_shell_tools
        install_tmux
        install_omzsh
        install_fnm
        install_go
        install_fonts
        setup_symlinks
        ;;
      --core)         setup_package_manager && install_core ;;
      --terminal)     install_kitty ;;
      --editor)       install_nvim ;;
      --shell-tools)  install_shell_tools ;;
      --tmux)         install_tmux ;;
      --omzsh)        install_omzsh ;;
      --fnm)          install_fnm ;;
      --go)           install_go ;;
      --rust)         install_rust ;;
      --fonts)        install_fonts ;;
      --symlinks)     setup_symlinks ;;
      --help)         usage ;;
      *) error "Unknown option: $arg"; usage; exit 1 ;;
    esac
  done

  echo ""
  success "Done!"
}

main "$@"
