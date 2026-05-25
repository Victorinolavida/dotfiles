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

;; GC tuning — LSP servers produce large output; default limits cause stutters
(setq gc-cons-threshold (* 100 1024 1024)
      read-process-output-max (* 1024 1024))

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
                      :rangeVariableTypes     t))))

  (add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode)

  ;; K = hover doc (replaces lsp-ui-doc-glance)
  (map! :map eglot-mode-map
        :n "K" #'eldoc-box-help-at-point
        :leader
        (:prefix ("c" . "code")
         :desc "Hover doc"    "K" #'eglot-help-at-point
         :desc "Rename"       "r" #'eglot-rename
         :desc "Code actions" "a" #'eglot-code-actions)))

;; Go debugger (delve via dape) — split layout like nvim dap-ui
(after! dape
  (setq dape-buffer-window-arrangement 'gud
        dape-info-hide-mode-line nil
        dape-stack-trace-levels 10)

  (add-to-list 'dape-configs
               '(go-debug-main
                 modes (go-mode go-ts-mode)
                 command "/Users/victorinolavida/go/bin/dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-cwd-fn
                 :request "launch"
                 :mode "debug"
                 :type "go"
                 :program "."))

  (add-to-list 'dape-configs
               '(go-debug-test
                 modes (go-mode go-ts-mode)
                 command "/Users/victorinolavida/go/bin/dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-cwd-fn
                 :request "launch"
                 :mode "test"
                 :type "go"
                 :program ".")))

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

(after! go-mode
  (map! :localleader
        :map go-mode-map
        (:prefix ("d" . "debug")
         :desc "Debug program"       "d" #'dape
         :desc "Debug last"          "l" #'dape-restart
         :desc "Toggle breakpoint"   "b" #'dape-breakpoint-toggle
         :desc "Continue"            "c" #'dape-continue
         :desc "Next"                "n" #'dape-next
         :desc "Step in"             "i" #'dape-step-in
         :desc "Step out"            "o" #'dape-step-out
         :desc "Quit"                "q" #'dape-quit)
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
         :desc "Clear tags"     "c" #'go-tag-clear)))


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
  (corfu-popupinfo-mode 1)
  (with-eval-after-load 'kind-icon
    (setq kind-icon-default-face 'corfu-default)
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)))

(use-package! kind-icon
  :after corfu
  :config
  (setq kind-icon-use-icons t
        kind-icon-blend-background nil))

;; Cape: extra completion sources
(after! cape
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; Format on save via apheleia (async subprocess — no LSP round-trip, no blocking :w)
(after! apheleia
  (setf (alist-get 'go-mode apheleia-mode-alist) 'gofumpt)
  (setf (alist-get 'gofumpt apheleia-formatters) '("gofumpt")))

;; Projectile: auto-discover projects (like nvim-project depth=2 under ~/Documents)
(after! projectile
  (setq projectile-project-search-path '(("~/Documents/" . 2))
        projectile-auto-discover t
        projectile-enable-caching t
        projectile-sort-order 'recently-active))

;; golangci-lint as secondary flycheck checker (eglot/flymake is primary)
(use-package! flycheck-golangci-lint
  :hook (go-mode . flycheck-golangci-lint-setup))

;; Prettier Go test output via gotest
(use-package! gotest
  :after go-mode
  :init
  (after! go-mode
    (map! :localleader
          :map go-mode-map
          (:prefix ("T" . "gotest pretty")
           :desc "Test at point"  "t" #'go-test-current-test
           :desc "Test file"      "f" #'go-test-current-file
           :desc "Test project"   "a" #'go-test-current-project
           :desc "Benchmark"      "b" #'go-test-current-benchmark
           :desc "Coverage"       "c" #'go-test-current-coverage))))

;; org-roam (Obsidian alternative — zettelkasten + backlinks)
(after! org-roam
  (setq org-roam-directory "~/org/roam/")
  (org-roam-db-autosync-mode)
  (map! :leader
        (:prefix ("n r" . "roam")
         :desc "Find node"     "f" #'org-roam-node-find
         :desc "Insert link"   "i" #'org-roam-node-insert
         :desc "Capture"       "c" #'org-roam-capture
         :desc "Toggle buffer" "b" #'org-roam-buffer-toggle
         :desc "Graph"         "g" #'org-roam-graph)))

;; xwidget-webkit as default browser (real WebKit engine)
(setq browse-url-browser-function #'xwidget-webkit-browse-url)
(map! :leader
      (:prefix ("o w" . "browser")
       :desc "Browse URL"          "w" #'xwidget-webkit-browse-url
       :desc "Browse URL at point" "p" (cmd! (xwidget-webkit-browse-url (thing-at-point 'url t)))
       :desc "Back"                "b" #'xwidget-webkit-back
       :desc "Reload"              "r" #'xwidget-webkit-reload))

;; Smudge — Spotify controller (needs OAuth2 credentials)
;; Get client-id/secret at https://developer.spotify.com/dashboard
(use-package! smudge
  :config
  (setq smudge-oauth2-client-id     (getenv "SPOTIFY_CLIENT_ID")
        smudge-oauth2-client-secret (getenv "SPOTIFY_CLIENT_SECRET")
        smudge-transport 'connect))

(after! smudge
  (map! :leader
        (:prefix ("o S" . "spotify")
         :desc "Track search"  "s" #'smudge-track-search
         :desc "My playlists"  "l" #'smudge-my-playlists
         :desc "Toggle play"   "t" #'smudge-controller-toggle-play
         :desc "Next"          "n" #'smudge-controller-next-track
         :desc "Prev"          "p" #'smudge-controller-previous-track
         :desc "Volume +"      "=" #'smudge-controller-volume-up
         :desc "Volume -"      "-" #'smudge-controller-volume-down)))

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

;; (after! go-mode
;;   (add-hook 'go-mode-hook #'gotest-ui-mode))

;; ~/.doom.d/config.el
(after! gotest-ui
  (add-hook 'go-mode-hook #'gotest-ui-mode)

  ;; Optional keybindings
  (map! :after gotest-ui-mode
        :map gotest-ui-mode-map
        :localleader
        :desc "Run Go tests" "t" #'gotest-ui-run
        :desc "Toggle Go test UI" "u" #'gotest-ui-mode))

;; go install golang.org/x/tools/gopls@latest
;; go install github.com/fatih/gomodifytags@latest
;; go install github.com/josharian/impl@latest
;; go install github.com/go-delve/delve/cmd/dlv@latest
;; go install github.com/rakyll/gotest@latest
;; go install github.com/onsi/ginkgo/ginkgo@latest  # if using Ginkgo

;; keep the cursor centered to avoid sudden scroll jumps
(require 'centered-cursor-mode)

;; disable in terminal modes
;; http://stackoverflow.com/a/6849467/519736
;; also disable in Info mode, because it breaks going back with the backspace key
(define-global-minor-mode my-global-centered-cursor-mode centered-cursor-mode
  (lambda ()
    (when (not (memq major-mode
                     (list 'Info-mode 'term-mode 'eshell-mode 'shell-mode 'erc-mode)))
      (centered-cursor-mode))))
(my-global-centered-cursor-mode 1)

(use-package treesit
  :mode (("\\.tsx\\'" . tsx-ts-mode)
         ("\\.js\\'"  . typescript-ts-mode)
         ("\\.mjs\\'" . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cjs\\'" . typescript-ts-mode)
         ("\\.ts\\'"  . typescript-ts-mode)
         ("\\.jsx\\'" . tsx-ts-mode)
         ("\\.json\\'" .  json-ts-mode)
         ("\\.Dockerfile\\'" . dockerfile-ts-mode)
         ("\\.prisma\\'" . prisma-ts-mode)
         ;; More modes defined here...
         )
  :preface
  (defun os/setup-install-grammars ()
    "Install Tree-sitter grammars if they are absent."
    (interactive)
    (dolist (grammar
             '((css . ("https://github.com/tree-sitter/tree-sitter-css" "v0.20.0"))
               (bash "https://github.com/tree-sitter/tree-sitter-bash")
               (html . ("https://github.com/tree-sitter/tree-sitter-html" "v0.20.1"))
               (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "v0.21.2" "src"))
               (json . ("https://github.com/tree-sitter/tree-sitter-json" "v0.20.2"))
               (python . ("https://github.com/tree-sitter/tree-sitter-python" "v0.20.4"))
               (go "https://github.com/tree-sitter/tree-sitter-go" "v0.20.0")
               (markdown "https://github.com/ikatyang/tree-sitter-markdown")
               (make "https://github.com/alemuller/tree-sitter-make")
               (elisp "https://github.com/Wilfred/tree-sitter-elisp")
               (cmake "https://github.com/uyha/tree-sitter-cmake")
               (c "https://github.com/tree-sitter/tree-sitter-c")
               (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
               (toml "https://github.com/tree-sitter/tree-sitter-toml")
               (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src"))
               (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src"))
               (yaml . ("https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0"))
               (prisma "https://github.com/victorhqc/tree-sitter-prisma")))
      (add-to-list 'treesit-language-source-alist grammar)
      ;; Only install `grammar' if we don't already have it
      ;; installed. However, if you want to *update* a grammar then
      ;; this obviously prevents that from happening.
      (unless (treesit-language-available-p (car grammar))
        (treesit-install-language-grammar (car grammar)))))

  ;; Optional, but recommended. Tree-sitter enabled major modes are
  ;; distinct from their ordinary counterparts.
  ;;
  ;; You can remap major modes with `major-mode-remap-alist'. Note
  ;; that this does *not* extend to hooks! Make sure you migrate them
  ;; also
  (dolist (mapping
           '((python-mode . python-ts-mode)
             (css-mode . css-ts-mode)
             (typescript-mode . typescript-ts-mode)
             (js-mode . typescript-ts-mode)
             (js2-mode . typescript-ts-mode)
             (c-mode . c-ts-mode)
             (c++-mode . c++-ts-mode)
             (c-or-c++-mode . c-or-c++-ts-mode)
             (bash-mode . bash-ts-mode)
             (css-mode . css-ts-mode)
             (json-mode . json-ts-mode)
             (js-json-mode . json-ts-mode)
             (sh-mode . bash-ts-mode)
             (sh-base-mode . bash-ts-mode)))
    (add-to-list 'major-mode-remap-alist mapping))
  :config
  (os/setup-install-grammars))

;; (use-package lsp-eslint
;;   :demand t
;;   :after lsp-mode)

(after! lsp-mode
  (setq lsp-gopls-staticcheck t
        lsp-gopls-complete-unimported t
        lsp-gopls-use-placeholders t))

(after! go-mode
  (add-hook 'before-save-hook #'lsp-format-buffer nil t)
  (add-hook 'before-save-hook #'lsp-organize-imports nil t))


(defun +go/run-gotest-ui ()
  "Run gotest-ui in the project root."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (ansi-term "gotest-ui ./..." "gotest-ui")
    ;; After returning, restore highlighting
    (add-hook 'term-exec-hook
              (lambda (&rest _)
                (dolist (buf (buffer-list))
                  (with-current-buffer buf
                    (when (eq major-mode 'go-mode)
                      (font-lock-fontify-buffer)))))
              nil 'local)))

(defun +go/run-gotest-ui ()
  "Run gotest-ui in vterm so it doesn't break syntax highlighting."
  (interactive)
  (let ((default-directory (projectile-project-root)))
    (vterm)
    (vterm-send-string "gotest-ui ./...\n")))
