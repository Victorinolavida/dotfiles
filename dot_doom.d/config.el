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
(setq display-line-numbers-type t)

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
        dape-stack-trace-levels 10))

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
        (:prefix ("t" . "test")
         :desc "Test at point"  "t" #'+go/test-current-function
         :desc "Test file"      "f" #'+go/test-current-file
         :desc "Test all"       "a" #'+go/test-all
         :desc "Test all+race"  "r" #'+go/test-all-race)
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
