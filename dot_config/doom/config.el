;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; IntelliOne Mono Nerd Font (installed via run_once_install.sh).
;; macOS registers the monospace variant as "IntoneMono NFM".
;; `doom-symbol-font' points at the Symbols Nerd Font (also installed by the
;; script) so glyphs/icons used by nerd-icons render correctly.
(setq doom-font        (font-spec :family "IntoneMono NFM" :size 14)
      doom-big-font    (font-spec :family "IntoneMono NFM" :size 20)
      doom-symbol-font (font-spec :family "Symbols Nerd Font Mono"))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; LSP servers stream large payloads; bump the per-read limit so eglot doesn't
;; stall on big responses. (GC is left to Doom's gcmh, which manages
;; `gc-cons-threshold' dynamically — a static `setq' here would just be
;; clobbered by gcmh. Tune `gcmh-high-cons-threshold' instead if needed.)
(setq read-process-output-max (* 1024 1024))

;; GUI Emacs.app inherits launchd's low file-descriptor limit
;; (`launchctl limit maxfiles' => 256), and emacs-mac's only file-notify backend
;; is kqueue (one FD per watched file). Poll for external buffer changes instead
;; of opening a watcher per visited file, so auto-revert doesn't compete with
;; eglot/treemacs for that tiny FD budget ("File watching not possible, no file
;; descriptor left"). See the eglot file-watch fix below for the main offender.
(setq auto-revert-use-notify nil)

;; Make CLI tools installed outside the GUI's PATH discoverable (dlv, gopls,
;; gofumpt, golangci-lint, emacs-lsp-booster, …). GUI Emacs on macOS doesn't
;; inherit the login shell's PATH; exec-path-from-shell imports it (PATH, GOBIN,
;; GOPATH, cargo/homebrew bins) — the canonical, maintained replacement for a
;; hand-rolled exec-path list.
(use-package! exec-path-from-shell
  :when (memq window-system '(mac ns x))
  :config
  (dolist (var '("GOPATH" "GOBIN"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;; Eglot: lighter LSP client, ~30% faster startup vs lsp-mode
(after! eglot
  (setq eglot-autoshutdown t
        eglot-sync-connect nil        ; async connect, don't block startup
        eglot-extend-to-xref t        ; xref jumps stay in eglot session
        eglot-report-progress nil)    ; silence minibuffer noise

  ;; gopls: same analyses/hints/lenses as previous lsp-go setup
  (setq-default eglot-workspace-configuration
    '(:gopls (:analyses     (:unusedparams t
                             :unusedwrite  t
                             :shadow       t
                             :useany       t
                             :nilness      t)
              :gofumpt          t
              :usePlaceholders  t
              :directoryFilters ["-vendor" "-node_modules" "-.git"]
              :codelenses (:generate         t
                           :gc_details       t
                           :run_govulncheck  t
                           :tidy             t
                           :upgrade_dependency t
                           :vendor           t)
              :hints (:assignVariableTypes    t
                      :compositeLiteralFields t
                      :compositeLiteralTypes  t
                      :constantValues         t
                      :functionTypeParameters t
                      :parameterNames         t
                      :rangeVariableTypes     t))
      ;; yaml-language-server: validation, hover, completion, and automatic
      ;; schema association from SchemaStore (GitHub Actions, docker-compose,
      ;; etc.). For Kubernetes manifests add a modeline at the top of the file:
      ;;   # yaml-language-server: $schema=<url-to-k8s-schema>
      ;; or use the kubernetes-json-schema URLs per resource kind.
      :yaml (:format       (:enable t)
             :validate     t
             :hover        t
             :completion   t
             :schemaStore  (:enable t))))

  (add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode)

  ;; Don't advertise dynamic file-watch registration to language servers. gopls
  ;; would otherwise ask Emacs to watch the entire module tree (up to
  ;; `eglot-max-file-watches' = 10000), which instantly exhausts GUI Emacs's
  ;; ~256 kqueue file descriptors on macOS and throws "File watching not
  ;; possible, no file descriptor left". With this off, gopls falls back to
  ;; watching the workspace itself — no Emacs FDs consumed.
  ;; Trade-off: changes made entirely *outside* Emacs (e.g. `git pull`, codegen)
  ;; may not refresh the server until you touch a file in that package or run
  ;; `M-x eglot-reconnect'. In-editor edits are unaffected.
  (cl-defmethod eglot-client-capabilities :around (server)
    (let* ((caps (cl-call-next-method))
           (ws (plist-get caps :workspace)))
      (when ws
        (plist-put ws :didChangeWatchedFiles '(:dynamicRegistration :json-false)))
      caps))

  ;; Go: organize imports (add/remove) on save via gopls code action — apheleia
  ;; only formats, it doesn't touch imports. No-op when eglot isn't managing.
  (defun +go/eglot-organize-imports ()
    (when (eglot-managed-p)
      (ignore-errors
        (eglot-code-action-organize-imports (point-min) (point-max)))))
  (dolist (hook '(go-mode-hook go-ts-mode-hook))
    (add-hook hook
              (lambda ()
                (add-hook 'before-save-hook #'+go/eglot-organize-imports nil t))))

  ;; K = hover doc (replaces lsp-ui-doc-glance)
  (map! :map eglot-mode-map
        :n "K" #'eldoc-box-help-at-point
        :leader
        (:prefix ("c" . "code")
         :desc "Hover doc"    "K" #'eldoc-box-help-at-point
         :desc "Rename"       "r" #'eglot-rename
         :desc "Code actions" "a" #'eglot-code-actions)))

;; Speed up eglot by routing LSP JSON through the emacs-lsp-booster binary.
;; Requires the `emacs-lsp-booster' executable on PATH (cargo install
;; emacs-lsp-booster). Falls back gracefully (logs a warning) if missing.
(use-package! eglot-booster
  :after eglot
  :config (eglot-booster-mode))

;; Fuzzy workspace-symbol jump across the whole project (SPC c j).
(use-package! consult-eglot
  :after eglot
  :init
  (map! :map eglot-mode-map
        :leader
        (:prefix ("c" . "code")
         :desc "Workspace symbols" "j" #'consult-eglot-symbols)))

;; docker-compose-mode — compose files get yaml-language-server (schema from
;; SchemaStore) just like plain YAML. docker-compose-mode derives from
;; yaml-mode but Doom runs the *exact* major-mode's local-vars-hook, so wire
;; eglot up explicitly here.
(use-package! docker-compose-mode
  :defer t
  :config
  (after! eglot
    (add-to-list 'eglot-server-programs
                 '(docker-compose-mode . ("yaml-language-server" "--stdio"))))
  (add-hook 'docker-compose-mode-local-vars-hook #'lsp! 'append))

;; Kubernetes — magit-style cluster overview (SPC o k k). Refresh is on demand
;; rather than on a timer so it doesn't hammer the cluster in the background.
(use-package! kubernetes
  :commands (kubernetes-overview)
  :init
  (map! :leader
        (:prefix ("o" . "open")
         (:prefix ("k" . "kubernetes")
          :desc "Overview" "k" #'kubernetes-overview)))
  :config
  (setq kubernetes-poll-frequency 3600
        kubernetes-redraw-frequency 3600))

(use-package! kubernetes-evil :after kubernetes)

;; Load dape on the first opened file. `dape-breakpoint-global-mode' is the
;; one autoloaded entry point that pulls in the whole dape feature, so this
;; both defines every `dape-*' command (no "commandp" errors from the SPC d
;; bindings) and lets you set/see breakpoints before ever starting a session.
(add-hook 'doom-first-file-hook #'dape-breakpoint-global-mode)

;; Go debugger (delve via dape) — split layout like nvim dap-ui
(after! dape
  ;; ---- Layout ----
  ;; 'left => info panels stack down the LEFT side, source stays full-height on
  ;; the RIGHT, and the REPL sits along the bottom (dap-ui style).
  ;; Other options: 'right (panels on right), 'gud (gdb-like), or nil.
  (setq dape-buffer-window-arrangement 'left
        dape-info-hide-mode-line t
        dape-stack-trace-levels 10)

  ;; ---- UI niceties ----
  ;; NOTE: `dape-inlay-hints' is left OFF. Its updater runs on a debounce
  ;; timer that fires `:variables' jsonrpc requests for the stopped frame,
  ;; which was throwing "Error running timer / jsonrpc--json-encode: Wrong
  ;; type argument: consp #<marker ...>" during sessions. Values are still
  ;; available on demand via eldoc hover (`K') and the Locals panel.
  (setq dape-info-variable-table-aligned t   ; align Locals/Watch columns
        dape-inlay-hints nil                  ; disabled: see note above
        dape-repl-echo-shell-output t)        ; program stdout echoes into the REPL

  ;; Which info buffers share a window (top group shows first):
  ;;   pane 1: Locals (scope) + Watch
  ;;   pane 2: Call stack + Threads
  ;;   pane 3: Breakpoints (+ Modules/Sources)
  (setq dape-info-buffer-window-groups
        '((dape-info-scope-mode dape-info-watch-mode)
          (dape-info-stack-mode dape-info-threads-mode)
          (dape-info-breakpoints-mode dape-info-modules-mode dape-info-sources-mode)))

  ;; ---- Breakpoints ----
  ;; `dape-breakpoint-global-mode' (which renders breakpoint indicators in
  ;; every buffer) is enabled from `doom-first-file-hook' below, not here, so
  ;; that dape loads early enough to set breakpoints before any session.

  ;; Persist breakpoints across *Emacs* restarts.
  ;; IMPORTANT: `dape-breakpoint-load' removes ALL current breakpoints before
  ;; loading, so it must NOT run on `dape-start-hook' — that wipes every
  ;; breakpoint each time you (re)start the debugger. Load once at startup,
  ;; save on exit.
  (setq dape-default-breakpoints-file
        (expand-file-name "dape-breakpoints" doom-cache-dir))
  (add-hook 'kill-emacs-hook #'dape-breakpoint-save)
  (when (file-exists-p dape-default-breakpoints-file)
    (dape-breakpoint-load))

  ;; Flash the line we stopped on so it's easy to spot.
  (add-hook 'dape-display-source-hook #'pulse-momentary-highlight-one-line)

  ;; ---- Go debug entry points (delve via DAP) ----
  ;; dape already ships a correct built-in `dlv' config; these add explicit
  ;; launch vs. test variants. The key fix vs. before: `ensure',
  ;; `command-cwd dape-command-cwd', and `port :autoport'. Without
  ;; `port :autoport' the `:autoport' placeholder in command-args is never
  ;; substituted, so delve is told to listen on the literal "127.0.0.1::autoport"
  ;; and the session never starts (hence no info panels / no stop highlight).
  (add-to-list 'dape-configs
               '(go-debug-main
                 modes (go-mode go-ts-mode)
                 ensure dape-ensure-command
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-command-cwd
                 port :autoport
                 :request "launch"
                 :type "go"
                 :mode "debug"
                 :cwd "."
                 :program "."))

  (add-to-list 'dape-configs
               '(go-debug-test
                 modes (go-mode go-ts-mode)
                 ensure dape-ensure-command
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-command-cwd
                 port :autoport
                 :request "launch"
                 :type "go"
                 :mode "test"
                 :cwd "."
                 :program "."))

  ;; Debug only the single test function under point (delve via DAP). Same as
  ;; `go-debug-test' but passes `-test.run ^TestName$' so just that test runs.
  ;; Reachable from the `SPC d d' config picker, like the other go-debug-* configs.
  (add-to-list 'dape-configs
               '(go-debug-test-at-point
                 modes (go-mode go-ts-mode)
                 ensure dape-ensure-command
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-command-cwd
                 port :autoport
                 :request "launch"
                 :type "go"
                 :mode "test"
                 :cwd "."
                 :program "."
                 :args (lambda ()
                         (if-let ((name (+go/test-name-at-point)))
                             (vector "-test.run" (format "^%s$" name))
                           (user-error "No Go test function at point"))))))

;; Go test runner (go.work workspace aware)
(defun +go/module-root ()
  "Find nearest go.mod directory from current buffer."
  (locate-dominating-file (buffer-file-name) "go.mod"))

(defun +go/test-current-file ()
  "Run tests in current file's package."
  (interactive)
  (let ((mod-root (+go/module-root)))
    (compile (format "cd %s && go test -v %s"
                     mod-root
                     (concat "./" (file-relative-name
                                   (file-name-directory (buffer-file-name))
                                   mod-root))))))

(defun +go/test-name-at-point ()
  "Name of the Go test function surrounding point, or nil."
  (which-function))

(defun +go/test-current-function ()
  "Run test function at point."
  (interactive)
  (let ((func (which-function))
        (mod-root (+go/module-root)))
    (if func
        (compile (format "cd %s && go test -v -run %s ./..."
                         mod-root func))
      (message "No function at point"))))

(defun +go/test-all ()
  "Run all tests in current module."
  (interactive)
  (compile (format "cd %s && go test -v ./..." (+go/module-root))))

(defun +go/test-all-race ()
  "Run all tests with race detector in current module."
  (interactive)
  (compile (format "cd %s && go test -v -race ./..." (+go/module-root))))

(defun +go/run ()
  "Run current Go file with go run."
  (interactive)
  (let ((dir (or (+go/module-root)
                 (file-name-directory (buffer-file-name)))))
    (compile (format "cd %s && go run %s" dir (buffer-file-name)))))

;; Global debug prefix (SPC d) — dape works for any language, so bind it
;; on the leader rather than the Go localleader.
(map! :leader
      (:prefix ("d" . "debug")
       :desc "Start / pick config"  "d" #'dape
       :desc "Restart"              "r" #'dape-restart
       :desc "Quit"                 "q" #'dape-quit
       :desc "Continue"             "c" #'dape-continue
       :desc "Next (step over)"     "n" #'dape-next
       :desc "Step in"              "i" #'dape-step-in
       :desc "Step out"             "o" #'dape-step-out
       :desc "Toggle breakpoint"    "b" #'dape-breakpoint-toggle
       :desc "Conditional bp"       "B" #'dape-breakpoint-expression
       :desc "Log breakpoint"       "l" #'dape-breakpoint-log
       :desc "Remove all bps"       "K" #'dape-breakpoint-remove-all
       :desc "Eval expression"      "e" #'dape-evaluate-expression
       :desc "Watch dwim"           "w" #'dape-watch-dwim
       :desc "REPL"                 "R" #'dape-repl
       :desc "Info panels"          "I" #'dape-info
       :desc "Stack up"             "k" #'dape-stack-select-up
       :desc "Stack down"           "j" #'dape-stack-select-down))

;; `+tree-sitter' remaps Go buffers to `go-ts-mode' (derives from prog-mode, so
;; it does NOT inherit `go-mode-map'). Bind both maps so the localleader keys
;; work regardless of which major mode is active.
(after! (:or go-mode go-ts-mode)
  (map! :localleader
        :map (go-mode-map go-ts-mode-map)
        (:prefix ("r" . "run")
         :desc "Run file"       "r" #'+go/run)
        (:prefix ("t" . "test")
         :desc "Test at point"  "t" #'+go/test-current-function
         :desc "Test file"      "f" #'+go/test-current-file
         :desc "Test all"       "a" #'+go/test-all
         :desc "Test all+race"  "R" #'+go/test-all-race)
        (:prefix ("s" . "struct tags")
         :desc "Add tag"        "a" #'go-tag-add
         :desc "Remove tag"     "r" #'go-tag-remove
         :desc "Clear tags"     "c" #'go-tag-clear)
        ;; Code generation. `go-impl' needs the `impl' binary and
        ;; `go-fill-struct' needs `fillstruct' on PATH (see install notes below).
        (:prefix ("i" . "implement/fill")
         :desc "Impl interface" "i" #'go-impl
         :desc "Fill struct"    "f" #'go-fill-struct)))


;; direnv — per-project environment (Go toolchain, PATH, secrets) loaded from
;; .envrc. The `:tools direnv' module already turns on `envrc-global-mode', so
;; every buffer (and the eglot/gopls process started in it) inherits the
;; project's direnv environment. This block just adds keybindings and makes the
;; env reload quietly. Needs the `direnv' binary on PATH (installed by
;; run_once_install.sh) — run `direnv allow' once per project, or `SPC e a'.
(after! envrc
  (setq envrc-none-lighter nil)         ; no modeline clutter when no .envrc
  (map! :leader
        (:prefix ("e" . "env/direnv")
         :desc "Allow .envrc"   "a" #'envrc-allow
         :desc "Deny .envrc"    "d" #'envrc-deny
         :desc "Reload"         "r" #'envrc-reload
         :desc "Reload all"     "R" #'envrc-reload-all)))

;; vterm
(after! vterm
  (setq vterm-max-scrollback 10000))

;; Better autocomplete (corfu tuning + cape sources + icons)
(after! corfu
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2
        corfu-preselect 'first
        corfu-cycle t
        corfu-quit-no-match 'separator
        corfu-preview-current 'insert
        corfu-popupinfo-delay '(0.3 . 0.2))
  (corfu-popupinfo-mode 1))
;; Completion icons are provided by the corfu `+icons' module flag
;; (nerd-icons-corfu), so no manual kind-icon setup is needed here.

;; Cape: extra completion sources
(after! cape
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; Format on save via apheleia (async subprocess — no LSP round-trip, no blocking :w)
(after! apheleia
  (setf (alist-get 'gofumpt apheleia-formatters) '("gofumpt"))
  ;; With `+tree-sitter' Go buffers run in `go-ts-mode', which has its own
  ;; apheleia-mode-alist entry (defaulting to gofmt) — remap both modes.
  (dolist (mode '(go-mode go-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'gofumpt)))

;; Projectile: auto-discover projects (like nvim-project depth=2 under ~/Documents)
(after! projectile
  (setq projectile-project-search-path '(("~/Documents/" . 2))
        projectile-auto-discover t
        projectile-enable-caching t
        projectile-sort-order 'recently-active))

;; Prettier Go test output via gotest
(use-package! gotest
  :after (:or go-mode go-ts-mode)
  :init
  (map! :localleader
        :map (go-mode-map go-ts-mode-map)
        (:prefix ("T" . "gotest pretty")
         :desc "Test at point"  "t" #'go-test-current-test
         :desc "Test file"      "f" #'go-test-current-file
         :desc "Test project"   "a" #'go-test-current-project
         :desc "Benchmark"      "b" #'go-test-current-benchmark
         :desc "Coverage"       "c" #'go-test-current-coverage
         :desc "Streaming UI"   "u" #'+go/run-gotest-ui)))

;; org-roam (Obsidian alternative — zettelkasten + backlinks)
(after! org-roam
  (setq org-roam-directory "~/org/roam/")
  ;; org-roam-db-autosync-mode errors out if the directory is missing
  (make-directory org-roam-directory t)
  (org-roam-db-autosync-mode)
  (map! :leader
        (:prefix ("n r" . "roam")
         :desc "Find node"     "f" #'org-roam-node-find
         :desc "Insert link"   "i" #'org-roam-node-insert
         :desc "Capture"       "c" #'org-roam-capture
         :desc "Toggle buffer" "b" #'org-roam-buffer-toggle
         :desc "Graph"         "g" #'org-roam-graph)))

;; xwidget-webkit as default browser (real WebKit engine). Only when this Emacs
;; was built with xwidgets — the Linux snap/PPA fallback may lack it, and
;; calling `xwidget-webkit-browse-url' there errors.
;; Requires Emacs 25+ built `--with-xwidgets' (GTK3 + WebKitGTK on Linux;
;; emacs-plus/emacs-mac `--with-xwidgets' on macOS). Verified on Emacs 29.4.
(when (featurep 'xwidget-internal)
  (setq browse-url-browser-function #'xwidget-webkit-browse-url))
(map! :leader
      (:prefix ("o w" . "browser")
       :desc "Browse URL"          "w" #'xwidget-webkit-browse-url
       :desc "Browse URL at point" "p" (cmd! (xwidget-webkit-browse-url (thing-at-point 'url t)))
       :desc "Back"                "b" #'xwidget-webkit-back
       :desc "Reload"              "r" #'xwidget-webkit-reload))

;; Verb — HTTP client in org-mode (Bruno/Postman alternative)
(use-package! verb
  :after org
  :config
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))

;; pgmacs — PostgreSQL table browser (DBeaver alternative)
(use-package! pgmacs
  :commands (pgmacs-open-string pgmacs-open))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; gotest-ui — live, streaming test results.
;; NOTE `gotest-ui-mode' is the MAJOR mode of the *gotest-ui* results buffer,
;; NOT a minor mode — it must never go on `go-mode-hook' (that would switch the
;; source buffer's major mode and clobber editing). The streaming runner is
;; bound as `SPC m T u' alongside the other gotest commands (see the gotest
;; use-package above); `+go/run-gotest-ui' shells out via vterm, so it needs no
;; eager load of the gotest-ui feature.

;; go install golang.org/x/tools/gopls@latest
;; go install github.com/fatih/gomodifytags@latest
;; go install github.com/josharian/impl@latest
;; go install github.com/go-delve/delve/cmd/dlv@latest
;; go install github.com/rakyll/gotest@latest
;; go install github.com/onsi/ginkgo/ginkgo@latest  # if using Ginkgo

;; keep the cursor vertically centered to avoid sudden scroll jumps.
;; Deferred to the first real buffer (via use-package!/:hook) so it doesn't load
;; centered-cursor-mode during startup.
;; Disabled in terminal/Info/comint modes where recentering misbehaves
;; (e.g. it breaks going back with backspace in Info). See
;; http://stackoverflow.com/a/6849467/519736
(use-package! centered-cursor-mode
  :defer t
  :init
  (define-global-minor-mode my-global-centered-cursor-mode centered-cursor-mode
    (lambda ()
      (unless (memq major-mode
                    '(Info-mode term-mode eshell-mode shell-mode erc-mode vterm-mode))
        (centered-cursor-mode))))
  (add-hook 'doom-first-buffer-hook #'my-global-centered-cursor-mode))

(defun +go/run-gotest-ui ()
  "Run gotest-ui in vterm so it doesn't break syntax highlighting."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (vterm)
    (vterm-send-string "gotest-ui ./...\n")))

;; ─────────────────────────────────────────────────────────────────────────────
;; Extra developer-experience packages (declared in packages.el)
;; ─────────────────────────────────────────────────────────────────────────────

;; eglot-x — LSP protocol extensions eglot omits (extra code actions, server
;; status, structural search/replace, etc.). Activated for every eglot session.
(use-package! eglot-x
  :after eglot
  :config (eglot-x-setup))

;; breadcrumb — header-line showing project path + symbol location (imenu).
(use-package! breadcrumb
  :hook (doom-first-buffer . breadcrumb-mode))

;; magit-todos — surface TODO/FIXME/HACK comments as a Magit status section
;; (pairs with the hl-todo module). Uses ripgrep, which ships with Doom.
(use-package! magit-todos
  :after magit
  :config (magit-todos-mode 1))

;; justl — transient UI for `just' recipes (needs the `just' binary on PATH).
(use-package! justl
  :commands (justl justl-exec-recipe-in-dir)
  :init
  (map! :leader
        (:prefix ("o" . "open")
         :desc "just recipes" "j" #'justl)))

;; consult-gh — GitHub CLI browser through consult/vertico (needs authed `gh').
(use-package! consult-gh
  :after consult
  :commands (consult-gh-search-repos consult-gh-default-action))

;; gptel — in-editor LLM client (configure your provider/API key separately).
(use-package! gptel
  :commands (gptel gptel-send gptel-menu))

;; combobulate — tree-sitter structural navigation/editing. Hook onto the
;; ts-modes that are actually in use here.
(use-package! combobulate
  :hook ((go-ts-mode yaml-ts-mode markdown-mode) . combobulate-mode))

;; devdocs — offline DevDocs viewer (run `M-x devdocs-install' per docset).
(use-package! devdocs
  :commands (devdocs-lookup devdocs-install devdocs-search)
  :init
  (map! :leader
        (:prefix ("o" . "open")
         :desc "devdocs lookup" "d" #'devdocs-lookup)))

;; indent-bars — tree-sitter-aware indent guides; most useful for YAML/k8s.
(use-package! indent-bars
  :hook ((yaml-mode yaml-ts-mode) . indent-bars-mode))

;; blamer — idle inline git blame (GitLens-style), on demand.
(use-package! blamer
  :commands (blamer-mode global-blamer-mode)
  :init
  (map! :leader
        (:prefix ("g" . "git")
         :desc "Toggle inline blame" "B" #'blamer-mode)))

;; dirvish — modern dired overhaul with previews and a sidebar.
(use-package! dirvish
  :after dired
  :config (dirvish-override-dired-mode))

;; org-modern — clean visual styling for org buffers (pairs with org+roam).
(use-package! org-modern
  :hook (org-mode . org-modern-mode))

;; protobuf-ts-mode — tree-sitter major mode for proto3 (.proto) files.
(use-package! protobuf-ts-mode
  :mode "\\.proto\\'")
