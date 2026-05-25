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
Config at `~/.doom.d/`. Doom itself installed by `run_once_install.sh.tmpl`.

Add `~/.emacs.d/bin` to `PATH` if not already present (`.zshrc` handles this).

### Yazi
Modern terminal file manager. Use `ya` instead of `yazi` to `cd` into the last visited directory on exit.

---

## Multiple GitHub Accounts

See `notes/multiple-github-accounts.md`.
