# Dotfiles

Personal dotfiles for macOS and Linux. Includes configs for Kitty, Zsh, Tmux, Neovim, and Yazi.

## Quick Install

```bash
git clone <your-repo-url> ~/.config/dotfiles
cd ~/.config/dotfiles
./install.sh --all
```

Or install individual components:

```bash
./install.sh --help
```

## install.sh

Handles all dependencies and symlinks automatically. Detects macOS (Homebrew) and Linux (apt) and installs the right packages for each.

| Flag | What it installs |
|------|-----------------|
| `--all` | Everything below |
| `--core` | git, curl, zsh |
| `--terminal` | Kitty |
| `--editor` | Neovim |
| `--shell-tools` | eza, bat, fzf, fd, zoxide, lazygit, yazi |
| `--tmux` | tmux + TPM |
| `--omzsh` | Oh My Zsh + Powerlevel10k + plugins |
| `--fnm` | Node version manager |
| `--go` | Go |
| `--rust` | Rust + Cargo |
| `--symlinks` | Dotfile symlinks only |

---

## Kitty

Cross-platform key bindings — uses `cmd+` on macOS and `ctrl+shift+` on Linux.

The `KITTY_OS_KEYS` env var (set in `.zshrc`) points kitty to the right key config file at startup.

**Symlink:**
```bash
ln -s ~/.config/dotfiles/kitty ~/.config/kitty
```

---

## Zsh

Requires Oh My Zsh + plugins. Run `./install.sh --omzsh` to set everything up.

**Plugins included:**
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `wd`
- `powerlevel10k` theme

**Symlink:**
```bash
ln -s ~/.config/dotfiles/.zshrc ~/.zshrc
```

---

## Tmux

Requires TPM (Tmux Plugin Manager). Run `./install.sh --tmux` to install tmux and TPM.

After symlinking the config, open tmux and press `prefix + I` to install all plugins.

**Symlink:**
```bash
ln -s ~/.config/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

---

## Neovim

Config lives in a separate repo: [minimal_nvim](https://github.com/Victorinolavida/minimal_nvim)

```bash
git clone https://github.com/Victorinolavida/minimal_nvim ~/.config/nvim
```

Or install via `./install.sh --editor`.

---

## Yazi

Modern terminal file manager replacing Ranger. Uses vim-like keybindings (`hjkl`) and opens files in Neovim.

Use `ya` instead of `yazi` to automatically `cd` into the last visited directory on exit.

**Install:**
```bash
./install.sh --rust && ./install.sh --shell-tools
```

**Symlink:**
```bash
ln -s ~/.config/dotfiles/yazi ~/.config/yazi
```

---

## Multiple GitHub Accounts

See `notes/` for setup instructions on managing multiple GitHub accounts.
