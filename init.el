;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setopt user-full-name "Leonardo Hernández Hernández"
		user-mail-address "leohdz172@proton.me")

(set-default-coding-systems 'utf-8)

(defun set-font-faces ()
  "Set fonts."
  (set-face-attribute
   'default nil :font "Iosevka NFM:size=13:antialias=true:autohint=true")
  (set-face-attribute
   'fixed-pitch nil :font "Iosevka NFM:size=13:antialias=true:autohint=true")
  (set-face-attribute
   'variable-pitch nil :font "Iosevka NF:size=13:antialias=true:autohint=true"))

(defun byte-compile-user-init-files ()
  "Byte compile `early-init-file' (if exists) and `user-init-file'."
  (interactive)
  (let ((byte-compile-warnings 'all))
	(when (file-exists-p early-init-file)
	  (byte-compile-file early-init-file))
	(byte-compile-file user-init-file)
	(native-compile user-init-file)))

(defun my-emacs-lisp-mode-hook ()
  "Hook to byte compile `early-init-file' and `user-init-file' on save."
  (when (or
		 (equal buffer-file-name early-init-file)
		 (equal buffer-file-name user-init-file))
	(add-hook 'after-save-hook 'byte-compile-user-init-files 0 t)))

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
      (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
		 "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
		 'silent 'inhibit-cookies)
	  (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setopt straight-check-for-modifications '(find-when-checking)
		;; Use `straight' for `use-package' expressions
		straight-use-package-by-default t
		;; Use shallow clone and single branch
		straight-vc-git-default-clone-depth '(1 single-branch))

;; `use-package' is bundled in emacs 29
(require 'use-package)
(setopt use-package-always-defer t)

;; Using garbage magic hack.
(use-package gcmh
  :autoload gcmh-mode
  :demand t
  ;; Use inmediatly instead of using a hook
  :config (gcmh-mode 1))

;; xdg.el is loaded in early-init
(declare-function xdg-data-home "xdg")
(declare-function xdg-config-home "xdg")
(use-package no-littering
  :demand t
  :autoload no-littering-theme-backups
  :init
  (setq-default
   ;; This dir stores config files
   no-littering-etc-directory (file-name-concat (xdg-config-home) "emacs/etc/")
   ;; This dir stores data files
   no-littering-var-directory (file-name-concat (xdg-data-home) "emacs/var/"))
  :config
  ;; Set `backup-directory-alist'
  (no-littering-theme-backups))

(use-package tramp
  :after no-littering ;; no-littering sets `backup-directory-alist'
  :straight (:type built-in)
  :custom
  (tramp-backup-directory-alist backup-directory-alist))

;; Configuration not related to packages
(use-package emacs
  :demand t
  :hook
  ;; Profile emacs startup
  (emacs-startup . (lambda ()
					 (message "*** Emacs loaded in %s with %d garbage collections."
							  (format "%.2f seconds"
									  (float-time
									   (time-subtract after-init-time before-init-time)))
							  gcs-done)))
  (emacs-lisp-mode . my-emacs-lisp-mode-hook)
  :bind (("C-x K" . kill-current-buffer)
		 ("C-c k" . kill-whole-line)
		 ("M-n" . "1")           ; The same as "C-u 1 C-v"
		 ("M-p" . [21 49 134217846]) ; The same as "C-u 1 M-v"
		 ("C-c q q" . save-buffers-kill-emacs)
		 ("C-c q r" . restart-emacs))
  :custom
  (create-lockfiles nil) ;; Do not write lockfiles, I'm the only one here
  (visible-bell t)       ;; Set up the visible bell
  (tab-bar-show 1)       ;; Do not show tab bar when there is only one tab
  (tab-bar-close-last-tab-choice 'delete-frame)
  (tab-width 4)
  (tab-always-indent 'complete)
  (auth-sources (list "~/.local/share/emacs/authinfo.gpg"))
  (inhibit-startup-message t)
  (enable-recursive-minibuffers t)
  (doc-view-mupdf-use-svg t)
  (doc-view-svg-foreground "white")
  (doc-view-svg-background "black")
  (use-short-answers t)
  (vc-follow-symlinks t)
  (require-final-newline t)
  (initial-scratch-message nil)
  (kill-do-not-save-duplicates t)

  :config
  (set-font-faces)
  (server-stop-automatically 'kill-terminal)
  (set-fringe-mode 6)
  (indent-tabs-mode 1)
  (modify-all-frames-parameters '((alpha-background . 95)))

  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (menu-bar-mode -1)

  (pixel-scroll-precision-mode 1)
  (delete-selection-mode 1)
  (repeat-mode 1)
  (column-number-mode 1)
  (minibuffer-depth-indicate-mode 1))

(use-package server
  :demand t
  :hook
  ;; Make sure the font is correctly loaded when running the daemon
  (server-after-make-frame . (lambda ()
							  (set-font-faces))))

(use-package sendmail
  :mode
  ("/tmp/neomutt-*" . mail-mode))

(use-package conf-mode
  :mode
  ("/etc/portage/package.*" . conf-space-mode)
  ("/etc/portage/env/*" . conf-unix-mode))

(use-package display-line-numbers
  :hook
  ;; Enable line numbers for some modes
  ((text-mode prog-mode conf-mode) . display-line-numbers-mode)
  :custom
  (display-line-numbers-type 'relative))

(use-package elec-pair
  :hook
  (after-init . electric-pair-mode))

(use-package treesit
  :straight (:type built-in)
  :custom
  (treesit-font-lock-level 4)
  :config
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode) t)
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode) t)
  (add-to-list 'major-mode-remap-alist
			   '(c-or-c++-mode . c-or-c++-ts-mode) t)
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode) t))

(use-package cc-mode
  :unless (treesit-available-p)
  :custom
  (c-basic-offset tab-width)
  :hook
  (c-mode . (lambda ()
			  (c-set-style "linux"))))

(use-package c-ts-mode
  :after treesit
  :custom
  (c-ts-mode-indent-offset tab-width)
  (c-ts-mode-indent-style 'linux))

(use-package sh-script
  :custom
  (sh-basic-offset (/ tab-width 2))
  :hook
  (sh-mode . (lambda ()
			   (setq indent-tabs-mode nil))))

(use-package savehist
  :hook
  (after-init . savehist-mode))

(use-package doom-themes
  :functions (doom-themes-org-config doom-themes-visual-bell-config)
  :demand t
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  :config
  (load-theme 'doom-dracula t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))

(use-package which-key
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.3))

(use-package unicode-fonts
  :hook
  (after-init . unicode-fonts-setup))

(use-package alert
  :custom
  (alert-default-style 'notifications))

(use-package ivy
  :defines (ivy-minibuffer-map
			ivy-switch-buffer-map
			ivy-reverse-i-search-map
			ivy-re-builders-alist
			ivy-height-alist
			ivy-format-function)
  :functions (ivy-format-function-line)
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)
         ("C-f" . ivy-alt-done)
         ("C-l" . ivy-alt-done)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :custom
  (ivy-use-virtual-buffers t)
  (ivy-wrap t)
  (ivy-count-format "%d/%d ")
  :hook (after-init . ivy-mode)
  :config
  ;; Use different regex strategies per completion command
  (push '(completion-at-point . ivy--regex-fuzzy) ivy-re-builders-alist) ;; This doesn't seem to work...
  (push '(swiper . ivy--regex-ignore-order) ivy-re-builders-alist)
  (push '(counsel-M-x . ivy--regex-ignore-order) ivy-re-builders-alist)

  ;; Set minibuffer height for different commands
  (setf (alist-get 'counsel-projectile-ag ivy-height-alist) 17)
  (setf (alist-get 'counsel-projectile-rg ivy-height-alist) 17)
  (setf (alist-get 'swiper ivy-height-alist) 17)
  (setf (alist-get 'counsel-switch-buffer ivy-height-alist) 17))

(use-package ivy-hydra
  :after (ivy hydra))

(use-package ivy-rich
  :defines (ivy-rich-display-transformers-list)
  :functions (ivy-format-function-line)
  :after (ivy counsel)
  :hook (after-init . ivy-rich-mode)
  :config
  (setq ivy-format-function #'ivy-format-function-line)
  (setq ivy-rich-display-transformers-list
        (plist-put ivy-rich-display-transformers-list
                   'ivy-switch-buffer
                   '(:columns
                     ((ivy-rich-candidate (:width 40))
                      (ivy-rich-switch-buffer-indicators (:width 4 :face error :align right)); return the buffer indicators
                      (ivy-rich-switch-buffer-major-mode (:width 12 :face warning))          ; return the major mode info
                      (ivy-rich-switch-buffer-project (:width 15 :face success))             ; return project name using `projectile'
                      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))))))  ; return file path relative to project root or `default-directory' if project is nil
                     :predicate
                     (lambda (cand)
                       (if-let ((buffer (get-buffer cand)))
                           ;; Don't mess with EXWM buffers
                           (with-current-buffer buffer
                             (not (derived-mode-p 'exwm-mode)))))))))


(use-package counsel
  :after ivy
  :demand t
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         ("C-M-j" . counsel-switch-buffer)
         ("C-M-l" . counsel-imenu)
         :map minibuffer-local-map
         ("C-r" . counsel-minibuffer-history))
  :custom
  (counsel-linux-app-format-function #'counsel-linux-app-format-function-name-only)
  (ivy-initial-inputs-alist nil) ;; Don't start searches with ^
  (counsel-switch-buffer-preview-virtual-buffers nil))

(use-package flx  ;; Improves sorting for fuzzy-matched results
  :defines (ivy-flx-limit)
  :after ivy
  :defer t
  :init
  (setq ivy-flx-limit 10000))

(use-package wgrep)

(use-package ivy-posframe
  :disabled
  :custom
  (ivy-posframe-width      115)
  (ivy-posframe-min-width  115)
  (ivy-posframe-height     10)
  (ivy-posframe-min-height 10)
  :config
  (setq ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-center)))
  (setq ivy-posframe-parameters '((parent-frame . nil)
                                  (left-fringe . 8)
                                  (right-fringe . 8)))
  (ivy-posframe-mode 1))

(use-package prescient
  :after counsel
  :hook
  (after-init . prescient-persist-mode))

(use-package ivy-prescient
  :after (ivy prescient)
  :hook
  (after-init . ivy-prescient-mode))

(use-package adaptive-wrap)

(use-package company
  :hook
  (after-init . global-company-mode))

(use-package ebuild-mode
  :hook
  (ebuild-mode . (lambda ()
	 (setq indent-tabs-mode t
		   sh-basic-offset 4))))

(use-package company-ebuild
  :after (company ebuild-mode)
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/company-ebuild.git"))

(use-package crontab-mode)

(use-package emacs-eix
  :disabled t
  :straight (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-eix.git"))

(use-package emacs-openrc
  :disabled t
  :straight (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-openrc.git"))

(use-package emacs-pkgcheck
  :disabled t
  :straight
  (:type git :host github :repo "pkgcore/pkgcheck" :files ("contrib/emacs/*.el")))

(use-package projectile
  :hook
  (after-init . projectile-mode)
  :custom
  (projectile-completion-system 'ivy)
  (projectile-enable-caching t)
  (projectile-switch-project-action #'projectile-find-file)
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (setopt projectile-auto-discover nil)
  (when (file-directory-p "~/source/repos")
    (setopt projectile-project-search-path '( ("~/source/repos" . 2 )))))

(use-package projectile-ripgrep
  :after projectile)

(use-package counsel-projectile
  :after (projectile counsel)
  :hook (after-init . counsel-projectile-mode))

(use-package magit
  :defines (+magit-open-windows-in-direction)
  :config
  (setq +magit-open-windows-in-direction 'left)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-openpgp-default-signing-key 'E538897EE11B9624)
  (magit-revision-show-gravatars '("^Author:     " . "^Commit:     "))
  (magit-diff-refine-hunk t))

(use-package flycheck
  :hook
  (after-init . global-flycheck-mode))

(use-package lua-mode
  :custom
  (lua-indent-level 2))

(use-package eglot
  :straight (:type built-in)
  :commands eglot eglot-ensure
  :defines (eglot-auto-display-help-buffer)
  :hook (((c-mode-common
		   c-ts-base-mode
		   yaml-ts-mode
		   python-mode
		   python-ts-mode
		   sh-mode
		   bash-ts-mode
		   lua-mode) . eglot-ensure))
  :custom
  (eglot-sync-connect 1)
  (eglot-connect-timeout 10)
  (eglot-autoshutdown t)
  (eglot-send-changes-idle-time 0.5)
  :config
  (setq
   ;; NOTE We disable eglot-auto-display-help-buffer because :select t in
   ;;      its popup rule causes eglot to steal focus too often.
   eglot-auto-display-help-buffer nil))

(use-package meson-mode)

(use-package vterm
  :disabled t
  :config
  (setq vterm-kill-buffer-on-exit t))

(use-package editorconfig
  :hook (after-init . editorconfig-mode))

(use-package markdown-mode)

(use-package git-gutter
  :hook (after-init . global-git-gutter-mode))

(use-package git-commit
  :hook
  (after-init . global-git-commit-mode)
  (git-commit-mode . (lambda () (setq fill-column 72)))
  :custom
  (git-commit-summary-max-length 50)
  (git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line)))

(use-package rmail
  :custom
  (rmail-primary-inbox-list '("imap://leohdz172%40proton.me@127.0.0.1:1143"))
  (rmail-preserve-inbox t)
  (rmail-remote-password-required t))

(use-package clipetty
  :hook (tty-setup . global-clipetty-mode))

(use-package saveplace
  :hook (after-init . save-place-mode))
;;; init.el ends here

