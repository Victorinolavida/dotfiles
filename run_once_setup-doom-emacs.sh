#!/usr/bin/env bash
# chezmoi run_once — bootstrap Doom Emacs if it isn't installed yet.
#
# Doom's private config lives in ~/.config/doom (tracked by chezmoi under
# dot_config/doom). This clones Doom core into ~/.config/emacs and installs
# its packages. Runs after run_once_install.sh (which installs Emacs + git).
set -e

EMACS_DIR="$HOME/.config/emacs"

# Already installed? Nothing to do.
if [ -x "$EMACS_DIR/bin/doom" ]; then
  echo "[doom] already installed at $EMACS_DIR — skipping"
  exit 0
fi

echo "[doom] installing Doom Emacs into $EMACS_DIR"
git clone --depth 1 https://github.com/doomemacs/core "$EMACS_DIR"

# -!         auto-accepts prompts (e.g. the envvar-file question) for non-interactive runs.
# --no-hooks skips `doom ci deploy-hooks`, which currently crashes on an upstream
#            regression in doomemacs/core (sh< returns a string that the hook-deploy
#            code treats as a (status . output) cons). Drop --no-hooks once fixed upstream.
"$EMACS_DIR/bin/doom" -! install --no-hooks

# Capture the current shell PATH into Doom's env file. macOS GUI Emacs (launched
# from Finder/dock) does NOT inherit the shell PATH, so without this it can't find
# tools like gopls/go — LSP silently fails. Re-run `doom sync --env` if you later
# install new CLI tools that Emacs needs to see.
"$EMACS_DIR/bin/doom" -! sync --env

echo "[doom] done. Launch Emacs; leader key is SPC."
