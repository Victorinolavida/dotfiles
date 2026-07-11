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
;; `relative' shows the current line's absolute number and relative offsets
;; above/below (nvim-style), which pairs well with evil motions like 5j / 3k.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
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

;; Neovim-style half-page scrolling: keep the cursor vertically centered after
;; C-d / C-u, like remapping them to `<C-d>zz` / `<C-u>zz` in Neovim.
;; (Doom already binds C-d/C-u to half-page scroll via `evil-want-C-u-scroll'.)
(defun +center-after-scroll-a (&rest _)
  "Recenter the window on point; used as :after advice for evil half-page scroll."
  (recenter))
(advice-add 'evil-scroll-down :after #'+center-after-scroll-a)
(advice-add 'evil-scroll-up   :after #'+center-after-scroll-a)


;;; ---- LSP (eglot): completion & imports -----------------------------------

;; Corfu: pop completions up automatically as you type, with a docs popup
;; beside the candidate (Doom leaves corfu manual-trigger by default).
(after! corfu
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2)
  (corfu-popupinfo-mode +1))

(after! eglot
  ;; Let orderless fuzzy-match inside LSP completions; eglot otherwise
  ;; restricts matching to a common prefix.
  (add-to-list 'completion-category-overrides '(eglot (styles orderless)))
  (add-to-list 'completion-category-overrides '(eglot-capf (styles orderless)))

  ;; gopls settings:
  ;;   usePlaceholders — fill function args as editable tab stops
  ;;   staticcheck     — richer diagnostics
  ;; (Completing symbols from unimported packages, and auto-adding their import,
  ;; is always-on in modern gopls — no setting needed.)
  (setq-default eglot-workspace-configuration
                '(:gopls (:usePlaceholders t
                          :staticcheck t))))

;; Go: format the buffer and organize imports on every save, via gopls/eglot.
(defun +go-eglot-organize-imports-h ()
  "Organize Go imports through gopls before saving."
  (when (eglot-managed-p)
    (ignore-errors (eglot-code-action-organize-imports (point-min) (point-max)))))

(add-hook! 'eglot-managed-mode-hook
  (defun +go-eglot-on-save-setup-h ()
    (when (derived-mode-p 'go-mode 'go-ts-mode)
      (add-hook 'before-save-hook #'eglot-format-buffer -10 t)
      (add-hook 'before-save-hook #'+go-eglot-organize-imports-h nil t))))


;;; ---- Debugger (dape) keybindings -----------------------------------------
;; IDE/VSCode-style function keys for fast stepping during a session, alongside
;; Doom's built-in `SPC d' debugger menu.
(defun +dape/start-or-continue ()
  "Continue the running debug session, or start one if none is active (F5)."
  (interactive)
  (condition-case nil
      (call-interactively #'dape-continue)
    (error (call-interactively #'dape))))

(when (modulep! :tools debugger)
  (map! :leader
        (:prefix ("d" . "debug")
         :desc "Start / continue"  "SPC" #'+dape/start-or-continue
         :desc "Start (choose)"    "d"   #'dape
         :desc "Continue"          "c"   #'dape-continue
         :desc "Step over (next)"  "n"   #'dape-next
         :desc "Step into"         "i"   #'dape-step-in
         :desc "Step out"          "o"   #'dape-step-out
         :desc "Toggle breakpoint" "b"   #'dape-breakpoint-toggle
         :desc "Remove all bkpts"  "B"   #'dape-breakpoint-remove-all
         :desc "REPL"              "r"   #'dape-repl
         :desc "Info"              "I"   #'dape-info
         :desc "Quit"              "q"   #'dape-quit)))
