#!/usr/bin/env bash
# Bootstrap: install chezmoi and apply dotfiles
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[install]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }

REPO="Victorinolavida"
SOURCE_DIR="$HOME/.config/dotfiles"

if ! command -v chezmoi &>/dev/null; then
  log "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)"
  success "chezmoi installed"
fi

log "Applying dotfiles..."
chezmoi init --apply --source "$SOURCE_DIR" "$REPO"
success "Done! Restart your shell."
