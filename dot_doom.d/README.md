# Doom Emacs Config

Multi-language development environment (Go primary) with eglot LSP, debugger, formatters, org-roam, Spotify, browser, HTTP client, and PostgreSQL browser.

## Requirements

### Emacs

```bash
brew install emacs-plus --with-native-comp
```

### Doom sync

After cloning or modifying `init.el` / `packages.el`:

```bash
~/.config/emacs/bin/doom sync
```

Then restart Emacs.

---

### Go tools

```bash
go install golang.org/x/tools/gopls@latest            # LSP server
go install mvdan.cc/gofumpt@latest                    # formatter (strict gofmt)
go install github.com/go-delve/delve/cmd/dlv@latest   # debugger
go install github.com/fatih/gomodifytags@latest       # struct tag editor (go-tag)
go install github.com/josharian/impl@latest           # interface stub generator
go install github.com/cweill/gotests/gotests@latest   # test stub generator
go install golang.org/x/tools/cmd/goimports@latest    # import manager
go install github.com/x-motemen/gore/cmd/gore@latest  # REPL
go install golang.org/x/tools/cmd/godoc@latest        # documentation
brew install golangci-lint                             # linter suite
```

### JavaScript

```bash
npm install -g typescript-language-server typescript
```

### Python

```bash
pip install pyright
```

### Rust

```bash
rustup component add rust-analyzer
```

### Spotify (smudge)

Create an app at https://developer.spotify.com/dashboard, then set env vars:

```bash
export SPOTIFY_CLIENT_ID="your_client_id"
export SPOTIFY_CLIENT_SECRET="your_client_secret"
```

---

## Modules enabled

| Module                  | Purpose                          |
| ----------------------- | -------------------------------- |
| `(lsp +eglot)`          | Eglot LSP client (fast, built-in)|
| `(go +lsp)`             | Go + gopls                       |
| `(javascript +lsp)`     | JS/TS + typescript-language-server |
| `(python +lsp +pyright)`| Python + pyright                 |
| `(rust +lsp)`           | Rust + rust-analyzer             |
| `debugger`              | DAP / dape (Delve for Go)        |
| `(format +onsave)`      | Apheleia async formatter         |
| `tree-sitter`           | Tree-sitter syntax highlighting  |
| `treemacs`              | File tree sidebar                |
| `(org +roam2)`          | Org-roam zettelkasten            |
| `data` / `yaml`         | JSON, TOML, YAML support         |
| `eww`                   | Text browser (fallback)          |
| `nav-flash`             | Cursor flash after jumps         |

---

## Keybindings

### LSP / Eglot (`SPC c`)

| Key       | Action              |
| --------- | ------------------- |
| `K`       | Hover doc (floating frame) |
| `SPC c K` | Hover doc at point  |
| `SPC c r` | Rename symbol       |
| `SPC c a` | Code actions        |
| `SPC c f` | Format buffer       |
| `gd`      | Go to definition    |
| `gr`      | Find references     |

### Go — Debugger (`SPC m d`)

| Key         | Action              |
| ----------- | ------------------- |
| `SPC m d d` | Start debug session |
| `SPC m d b` | Toggle breakpoint   |
| `SPC m d c` | Continue            |
| `SPC m d n` | Next (step over)    |
| `SPC m d i` | Step in             |
| `SPC m d o` | Step out            |
| `SPC m d l` | Restart last        |
| `SPC m d q` | Quit                |

### Go — Tests (`SPC m t`)

| Key         | Action                  |
| ----------- | ----------------------- |
| `SPC m t t` | Test at point           |
| `SPC m t f` | Test file               |
| `SPC m t a` | Test all                |
| `SPC m t r` | Test all + race detector|

### Go — Tests pretty (`SPC m T`)

| Key         | Action               |
| ----------- | -------------------- |
| `SPC m T t` | Test at point (gotest) |
| `SPC m T f` | Test file            |
| `SPC m T a` | Test project         |
| `SPC m T b` | Benchmark            |
| `SPC m T c` | Coverage             |

### Go — Struct tags (`SPC m s`)

| Key         | Action            |
| ----------- | ----------------- |
| `SPC m s a` | Add struct tag    |
| `SPC m s r` | Remove struct tag |
| `SPC m s c` | Clear all tags    |

### File tree (`SPC o p`)

| Key       | Action                     |
| --------- | -------------------------- |
| `SPC o p` | Toggle treemacs            |
| `SPC o P` | Focus treemacs on file     |

### Org-roam (`SPC n r`)

| Key         | Action              |
| ----------- | ------------------- |
| `SPC n r f` | Find / create node  |
| `SPC n r i` | Insert link         |
| `SPC n r c` | Capture note        |
| `SPC n r b` | Toggle backlinks    |
| `SPC n r g` | Open graph view     |

### Browser — xwidget-webkit (`SPC o w`)

| Key         | Action              |
| ----------- | ------------------- |
| `SPC o w w` | Open URL            |
| `SPC o w p` | Open URL at point   |
| `SPC o w b` | Back                |
| `SPC o w r` | Reload              |

### Spotify (`SPC o S`)

| Key           | Action          |
| ------------- | --------------- |
| `SPC o S s`   | Search tracks   |
| `SPC o S l`   | My playlists    |
| `SPC o S t`   | Toggle play     |
| `SPC o S n`   | Next track      |
| `SPC o S p`   | Previous track  |
| `SPC o S =`   | Volume up       |
| `SPC o S -`   | Volume down     |

### HTTP client — verb (`C-c C-r` in org)

Write requests in org files:

```org
* My API                                    :verb:
** Get users
get https://api.example.com/users

** Create user
post https://api.example.com/users
Content-Type: application/json

{
  "name": "John"
}
```

`C-c C-r s` — send request, `C-c C-r r` — show response.

### PostgreSQL — pgmacs

```
M-x pgmacs-open-string
```

Connection string: `host=localhost port=5432 dbname=mydb user=postgres`

---

## Formatting

On save via apheleia (async — no blocking `:w`):

| Language   | Formatter             |
| ---------- | --------------------- |
| Go         | `gofumpt`             |
| JS/TS      | `prettier` (if found) |
| Python     | `black` (if found)    |
| Rust       | `rustfmt`             |

Manual format: `SPC c f`
