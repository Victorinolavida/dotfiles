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

;; Go debugger (delve via dape — dlv config built-in)
(after! dape
  (setq dape-buffer-window-arrangement 'right))

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
         :desc "Test all+race"  "r" #'+go/test-all-race)))


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
