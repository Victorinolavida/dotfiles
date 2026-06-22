# Doom Emacs Config

Multi-language development environment (Go primary) with eglot LSP, debugger, formatters, org-roam, browser, HTTP client, and PostgreSQL browser.

## Requirements

### Emacs

```bash
brew tap railwaycat/emacsmacport
brew install emacs-mac@29 --with-xwidgets
# cp not symlink — Spotlight does not index symlinks
cp -r /opt/homebrew/opt/emacs-mac@29/Emacs.app /Applications/Emacs.app
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
rustup component add clippy        # rust-analyzer runs clippy for diagnostics
```

### YAML / docker-compose / Kubernetes manifests

```bash
npm install -g yaml-language-server
```

Schemas are pulled automatically from SchemaStore (GitHub Actions,
docker-compose, etc.). For Kubernetes manifests, add a modeline at the top of
the file so the server validates against the right schema:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0-standalone-strict/deployment.json
```

### Docker

```bash
npm install -g dockerfile-language-server-nodejs   # docker-langserver
```

### Kubernetes (cluster UI)

`SPC o k k` opens a magit-style overview of the cluster in the current
`kubectl` context. Requires `kubectl` on `PATH`.

---

## Modules enabled

| Module                  | Purpose                          |
| ----------------------- | -------------------------------- |
| `(lsp +eglot)`          | Eglot LSP client (fast, built-in)|
| `(go +lsp)`             | Go + gopls                       |
| `(javascript +lsp)`     | JS/TS + typescript-language-server |
| `(python +lsp +pyright)`| Python + pyright                 |
| `(rust +lsp)`           | Rust + rust-analyzer             |
| `(yaml +lsp)`           | YAML + yaml-language-server      |
| `(docker +lsp)`         | Dockerfile + docker-langserver   |
| `kubernetes`            | Cluster overview UI (`SPC o k k`)|
| `debugger`              | DAP / dape (Delve for Go)        |
| `(format +onsave)`      | Apheleia async formatter         |
| `tree-sitter`           | Tree-sitter syntax highlighting  |
| `treemacs`              | File tree sidebar                |
| `(org +roam)`           | Org-roam zettelkasten            |
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

### Go — Run (`SPC m r`)

| Key         | Action         |
| ----------- | -------------- |
| `SPC m r r` | `go run` file  |

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

### Rust — Cargo (`SPC m b` / `SPC m t`)

Provided by the `rust` module (rustic):

| Key         | Action         |
| ----------- | -------------- |
| `SPC m b b` | cargo build    |
| `SPC m b c` | cargo check    |
| `SPC m b C` | cargo clippy   |
| `SPC m b r` | cargo run      |
| `SPC m b f` | cargo fmt      |
| `SPC m t a` | cargo test all |
| `SPC m t t` | test at point  |

### Kubernetes (`SPC o k`)

| Key         | Action                  |
| ----------- | ----------------------- |
| `SPC o k k` | Cluster overview        |

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
