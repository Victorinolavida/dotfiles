# Dotfiles

Personal dotfiles for macOS and Linux. Managed with [chezmoi](https://chezmoi.io).

## Quick Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Victorinolavida
```

Or if chezmoi is already installed:

```bash
chezmoi init --apply Victorinolavida
```

---

## How it works

[chezmoi](https://chezmoi.io) manages symlinks and file application. On first run it also executes `run_once_install.sh.tmpl` to install all packages.

---

## `run_once_install.sh.tmpl`

This script runs automatically when you first apply the dotfiles (or whenever its content changes). It bootstraps your environment end-to-end.

### What it installs

**macOS** (via Homebrew)
- CLI tools: `git`, `curl`, `zsh`, `eza`, `bat`, `fzf`, `fd`, `zoxide`, `lazygit`, `tmux`, `ripgrep`, `go`, `neovim`, `yazi`
- Casks: `ghostty`, `font-jetbrains-mono-nerd-font`, `font-intone-mono-nerd-font`
- Emacs: `emacs-mac@29` (railwaycat tap, with xwidgets + native compilation)
- Node version manager: `fnm`

**Linux** (via apt + GitHub releases)
- apt: `git`, `curl`, `zsh`, `tmux`, `ripgrep`, `build-essential`, `fzf`, `fd-find`, `zoxide`, `golang-go`
- `eza` via the official gierens apt repo
- `bat` (with a `bat` → `batcat` symlink on Ubuntu)
- `lazygit`, `yazi` — downloaded from GitHub releases
- `neovim` via snap
- `ghostty` — prints a manual-install reminder (no official Linux package)
- Emacs: snap (preferred) or kelleyk PPA
- `fnm`, Rust/Cargo, JetBrainsMono Nerd Font

**Both platforms**
- Oh My Zsh
- Tmux Plugin Manager (TPM) → `~/.tmux/plugins/tpm`
- Doom Emacs → `~/.emacs.d`
- `dlv` (Go debugger, via `go install`)

### When it runs

chezmoi tracks a hash of the script. It runs automatically on:
- `chezmoi init --apply` (first-time setup)
- `chezmoi apply` / `chezmoi update` — only if the script content has changed since the last run

### Force re-run

To re-run the script without changing its content:

```bash
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

| Command | What it does |
|---------|-------------|
| `chezmoi apply` | Apply config changes to `$HOME` |
| `chezmoi diff` | Preview what would change |
| `chezmoi edit ~/.zshrc` | Edit source file and apply |
| `chezmoi cd` | Jump into source directory |
| `chezmoi update` | Pull latest + apply |

---

## Source structure

```
dotfiles/
├── dot_zshrc              → ~/.zshrc
├── dot_tmux.conf          → ~/.tmux.conf
├── dot_aerospace.toml     → ~/.aerospace.toml
├── dot_wezterm.lua        → ~/.wezterm.lua
├── dot_config/
│   ├── doom/              → ~/.config/doom/
│   ├── ghostty/           → ~/.config/ghostty/
│   ├── kitty/             → ~/.config/kitty/
│   └── yazi/              → ~/.config/yazi/
├── dot_local/bin/         → ~/.local/bin/  (tmux scripts)
├── run_once_install.sh.tmpl  — package installs (runs once)
├── .chezmoi.toml.tmpl     — chezmoi config
├── .chezmoiexternal.toml  — external repos (nvim)
└── .chezmoiignore         — files chezmoi skips
```

---

## Configs

### Zsh
Requires Oh My Zsh + plugins (installed by `run_once_install.sh.tmpl`).

Plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `wd`, `powerlevel10k` theme.

### Kitty
Cross-platform key bindings. `os-keys.conf` is generated from a chezmoi template — uses `cmd+` on macOS and `ctrl+shift+` on Linux. No manual symlink needed.

### Ghostty
Config at `~/.config/ghostty/config`.

### Tmux
Requires TPM. Installed by `run_once_install.sh.tmpl`. After first apply, open tmux and press `prefix + I` to install plugins.

### Neovim
Config sourced from [minimal_nvim](https://github.com/Victorinolavida/minimal_nvim) via `.chezmoiexternal.toml`. chezmoi clones it automatically to `~/.config/nvim`.

### Doom Emacs
Config at `~/.config/doom/` (managed by chezmoi). Doom itself cloned to `~/.emacs.d` by `run_once_install.sh.tmpl`.

Add `~/.emacs.d/bin` to `PATH` if not already present (`.zshrc` handles this).

### Yazi
Modern terminal file manager. Use `ya` instead of `yazi` to `cd` into the last visited directory on exit.

---

## Troubleshooting

### OMZ plugins/theme not found after fresh install

chezmoi creates `~/.oh-my-zsh/custom/` (for plugins) *before* the install script runs, which can cause the OMZ installer to be skipped if the check tests the directory rather than the actual install. The script now checks for `oh-my-zsh.sh` instead.

If you still see `plugin not found` or `theme not found` errors, force-refresh the external repos:

```bash
chezmoi apply --force --refresh-externals=always
```

### oh-my-zsh.sh not found

OMZ wasn't installed. Remove the partial directory and re-run:

```bash
rm -rf ~/.oh-my-zsh
bash <(chezmoi execute-template < ~/.local/share/chezmoi/run_once_install.sh.tmpl)
chezmoi apply --force --refresh-externals=always
```

### direnv: command not found

`direnv` is installed by the run_once script. If it's missing, install manually:

```bash
brew install direnv        # macOS
sudo apt-get install direnv  # Linux
```

---

## Multiple GitHub Accounts

See `notes/multiple-github-accounts.md`.
