# tmux Cheatsheet

**Prefix:** `Ctrl+x`  
**Copy mode:** vi keys

---

## Panes

| Key | Action |
|-----|--------|
| `prefix + h/j/k/l` | Navigate panes (vim) |
| `prefix + %` or `prefix + \|` | Split horizontal |
| `prefix + "` or `prefix + -` | Split vertical |
| `Alt + ↑/↓/←/→` | Resize pane (5 cells) |

---

## Windows

| Key | Action |
|-----|--------|
| `Alt + 1..9` | Jump to window N |
| `prefix + r` | Reload tmux.conf |

---

## Popups (no prefix)

| Key | Action |
|-----|--------|
| `Alt + g` | Scratch session (toggle floating terminal) |
| `Alt + t` | Shell popup (75% screen) |

---

## Sessions & Navigation

| Key | Action |
|-----|--------|
| `prefix + f` | Sessionizer (fuzzy project picker) |
| `prefix + o` | SessionX (session manager UI) |

---

## Plugins

| Key | Action |
|-----|--------|
| `prefix + /` | Fuzzback (fuzzy search scrollback) |
| `prefix + b` | Menus (context menu) |
| `prefix + g` | NeoLazygit (git UI popup) |

### tmux-logging

| Key | Action |
|-----|--------|
| `prefix + shift + p` | Toggle pane logging |
| `prefix + alt + p` | Save visible pane to file |
| `prefix + alt + shift + p` | Save full pane history to file |
| `prefix + shift + h` | Clear pane history |

### extrakto

| Key | Action |
|-----|--------|
| `prefix + e` | Fuzzy extract text from pane → copy or insert |

### tmux-which-key

| Key | Action |
|-----|--------|
| `prefix + ?` | Show all keybindings popup |

### tmux-notify

| Key | Action |
|-----|--------|
| `prefix + m` | Monitor pane — notify when command finishes |
| `prefix + alt + m` | Cancel monitor |

---

## Copy Mode (`prefix + [`)

| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `y` | Copy selection → clipboard |
| `Enter` | Copy selection → clipboard |
| Mouse drag | Copy selection → clipboard |

---

## Scripts (CLI)

| Command | Action |
|---------|--------|
| `go-layout [name]` | Open Go dev session (editor + shell + test pane) |
| `tmux-sessionizer` | Fuzzy-find project and open/attach session |
