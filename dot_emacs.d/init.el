;;; Startup

;;; Quiet down benign upstream warnings (magit/llama compile nits,
;;; Eglot/jsonrpc deprecation, etc.) — keep real errors visible.
(setq native-comp-async-report-warnings-errors 'silent) ; compile-time
(setq warning-minimum-level :error)                      ; runtime popups

;;; PACKAGE LIST
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("elpa" . "https://elpa.gnu.org/packages/")))

;;; BOOTSTRAP USE-PACKAGE
(package-initialize)
(setq use-package-always-ensure t)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;;; UNDO
;; Vim style undo not needed for emacs 28
(use-package undo-fu)

;;; Vim Bindings
(use-package evil
  :demand t
  :bind (("<escape>" . keyboard-escape-quit))
  :init
  ;; allows for using cgn
  ;; (setq evil-search-module 'evil-search)
  (setq evil-want-keybinding nil)
  ;; no vim insert bindings
  (setq evil-undo-system 'undo-fu)
  :config
  (evil-mode 1))

;;; Vim Bindings Everywhere else
(use-package evil-collection
  :after evil
  :config
  (setq evil-want-integration t)
  (evil-collection-init))

;;; macOS: Meta is the Option/Alt key (like Alt on PC/Linux);
;;; Command becomes Super. Set both mac-* and ns-* so it works
;;; regardless of which Emacs macOS build is in use.
(setq mac-option-modifier 'meta)
(setq mac-command-modifier 'super)
(setq ns-option-modifier 'meta)
(setq ns-command-modifier 'super)
;; Right Option stays "none" so it types special chars (@ [] {} \ …)
(setq mac-right-option-modifier 'none)
(setq ns-right-option-modifier 'none)

;;; GUI Emacs on macOS doesn't inherit the shell PATH, so it can't
;;; find gopls/dlv/goimports (all in ~/go/bin). Import the shell env.
(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize))
  ;; Belt-and-suspenders: ensure Go bin dir is on the path.
  (let ((gobin (expand-file-name "~/go/bin")))
    (add-to-list 'exec-path gobin)
    (setenv "PATH" (concat gobin path-separator (getenv "PATH")))))

(use-package vertico
  :config
  (vertico-mode))

;;; ---- "Doom-lite" layer -------------------------------------------------

;;; Better minibuffer: fuzzy-ish matching + rich annotations
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode))

;;; Fast search / navigation commands (Doom binds these under SPC)
(use-package consult)

;;; Git porcelain (the killer Emacs app)
(use-package magit)

;;; Project management, Doom-style (add + search known projects)
(use-package projectile
  :init
  (projectile-mode 1)
  :config
  ;; Auto-discover projects under these roots (adjust to taste)
  (setq projectile-project-search-path '("~/go/src/" "~/projects/" "~/"))
  (setq projectile-switch-project-action #'projectile-find-file)
  ;; Persist the known-projects list across restarts, and write it to
  ;; disk immediately whenever a project is added/removed (so it isn't
  ;; lost if Emacs is killed rather than quit cleanly).
  (setq projectile-known-projects-file
        (expand-file-name "projectile-known-projects.eld" user-emacs-directory))
  (setq projectile-enable-caching t)
  (advice-add 'projectile-add-known-project :after
              (lambda (&rest _) (projectile-save-known-projects))))

;;; Discoverability: popup showing available keys
;; (Built into Emacs 30.1+, but a package on 29.x)
(use-package which-key
  :config
  (setq which-key-idle-delay 0.3)
  (which-key-mode))

;;; SPC leader key, Doom-style
(use-package general
  :after evil
  :config
  (general-create-definer my/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC")

  ;; nvim-style g-prefix LSP motions (only active in Eglot buffers)
  (general-define-key
   :states '(normal visual)
   :keymaps 'eglot-mode-map
   "gd" '(xref-find-definitions   :which-key "go to definition")
   "gi" '(eglot-find-implementation :which-key "go to implementation")
   "gr" '(xref-find-references    :which-key "references")
   "gD" '(eglot-find-declaration  :which-key "declaration")
   "gt" '(eglot-find-typeDefinition :which-key "type definition")
   "K"  '(eldoc-doc-buffer        :which-key "hover docs"))

  (my/leader
    "SPC" '(consult-buffer :which-key "switch buffer")
    ":"   '(execute-extended-command :which-key "M-x")

    ;; files
    "f"  '(:ignore t :which-key "file")
    "ff" '(find-file :which-key "find file")
    "fr" '(consult-recent-file :which-key "recent file")
    "fs" '(save-buffer :which-key "save")

    ;; buffers
    "b"  '(:ignore t :which-key "buffer")
    "bb" '(consult-buffer :which-key "switch")
    "bk" '(kill-current-buffer :which-key "kill")
    "bd" '(kill-current-buffer :which-key "kill")

    ;; search
    "s"  '(:ignore t :which-key "search")
    "ss" '(consult-line :which-key "search buffer")
    "sp" '(consult-ripgrep :which-key "search project")

    ;; project (projectile — add + search known projects)
    "p"  '(:ignore t :which-key "project")
    "pf" '(projectile-find-file :which-key "find file")
    "pp" '(projectile-switch-project :which-key "switch project")
    "pa" '(projectile-add-known-project :which-key "add project")
    "pd" '(projectile-remove-known-project :which-key "remove project")
    "pi" '(projectile-discover-projects-in-search-path :which-key "discover projects")

    ;; git
    "g"  '(:ignore t :which-key "git")
    "gg" '(magit-status :which-key "status")
    "gb" '(magit-blame :which-key "blame")
    "gl" '(magit-log-current :which-key "log")

    ;; code / LSP (Eglot)
    "c"  '(:ignore t :which-key "code")
    "ca" '(eglot-code-actions :which-key "code action")
    "cr" '(eglot-rename :which-key "rename")
    "cf" '(eglot-format-buffer :which-key "format")
    "cd" '(xref-find-definitions :which-key "definition")

    ;; windows
    "w"  '(:ignore t :which-key "window")
    "wv" '(split-window-right :which-key "split right")
    "ws" '(split-window-below :which-key "split below")
    "wd" '(delete-window :which-key "delete")
    "wo" '(delete-other-windows :which-key "only")

    ;; help
    "h"  '(:ignore t :which-key "help")
    "hf" '(describe-function :which-key "function")
    "hv" '(describe-variable :which-key "variable")
    "hk" '(describe-key :which-key "key")))

;;; A few sane defaults Doom sets for you
(setq inhibit-startup-screen t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(save-place-mode 1)                 ; remember cursor position in files
(recentf-mode 1)                    ; track recent files (for SPC f r)
(setq make-backup-files nil)        ; no init.el~ clutter

;;; ------------------------------------------------------------------------

;;; In-buffer completion popup (vertico only covers the minibuffer).
;;; This is what shows LSP (Eglot) completions as you type.
(use-package corfu
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode)          ; docs popup beside the candidate
  :custom
  (corfu-auto t)                  ; pop up automatically
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 1)           ; after 1 char (nice for LSP)
  (corfu-cycle t)
  (corfu-popupinfo-delay '(0.5 . 0.2)))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file))

;;; Let orderless fuzzy-match inside LSP completions (Eglot otherwise
;;; forces its own style and only matches the prefix).
(with-eval-after-load 'orderless
  (setq completion-category-overrides
        (append completion-category-overrides
                '((eglot (styles orderless))
                  (eglot-capf (styles orderless))))))

;;; Tree-sitter grammar sources (install with
;;; M-x treesit-install-language-grammar if ever missing)
(setq treesit-language-source-alist
      '((go    . ("https://github.com/tree-sitter/tree-sitter-go"))
        (gomod . ("https://github.com/camdencheek/tree-sitter-go-mod"))))

;;; Go (tree-sitter major modes, built into Emacs 29)
(use-package go-ts-mode
  :ensure nil
  :mode (("\\.go\\'"     . go-ts-mode)
         ("/go\\.mod\\'" . go-mod-ts-mode))
  :hook (go-ts-mode . eglot-ensure)
  :config
  (setq go-ts-mode-indent-offset 4))

;;; Markdown mode — lets Eglot fontify gopls hover docs (K) with
;;; proper headers, bold, and syntax-highlighted code blocks.
(use-package markdown-mode)

;;; LSP via Eglot (built-in); gopls is already installed
(use-package eglot
  :ensure nil
  :config
  (add-to-list 'eglot-server-programs
               '((go-ts-mode go-mode) . ("gopls")))

  ;; Show the `K' documentation buffer only in a bottom pane.
  (add-to-list 'display-buffer-alist
               '("^\\*eldoc"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.3)
                 (dedicated . t)))
  ;; Nicer, taller docs; keep echo-area hints multiline too.
  (setq eldoc-echo-area-use-multiline-p t)
  (setq eldoc-doc-buffer-separator (make-string 40 ?─))
  ;; Format + organize imports on save
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (when (derived-mode-p 'go-ts-mode)
                (add-hook 'before-save-hook #'eglot-format-buffer -10 t)
                (add-hook 'before-save-hook
                          (lambda ()
                            (call-interactively
                             #'eglot-code-action-organize-imports))
                          nil t)))))

;;; Debugging (dlv is already installed)
(use-package dape
  :config
  (setq dape-buffer-window-arrangement 'right))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(general consult marginalia orderless vertico undo-fu evil-collection dape corfu cape)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
