;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.

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
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
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
(if (daemonp)
	(setopt use-package-always-demand t)
  (setopt use-package-always-defer t))

;; Using garbage magic hack.
(use-package gcmh
  :autoload gcmh-mode
  :demand t
  ;; Use inmediatly instead of using a hook
  :config (gcmh-mode 1))

;; xdg.el is loaded in `early-init-file'
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
		 ("C-c q q" . save-buffers-kill-emacs)
		 ("C-c q r" . restart-emacs))
  :custom
  (create-lockfiles nil) ;; Do not write lockfiles, I'm the only one here
  (visible-bell t)       ;; Set up the visible bell
  (tab-bar-show 1)       ;; Do not show tab bar when there is only one tab
  (tab-bar-close-last-tab-choice 'delete-frame)
  (tab-width 4)
  (tab-always-indent 'complete)
  (auth-sources (list (file-name-concat (xdg-data-home) "emacs/authinfo.gpg")))
  (inhibit-startup-message t)
  (enable-recursive-minibuffers t)
  (doc-view-mupdf-use-svg t)
  (doc-view-svg-foreground "white")
  (doc-view-svg-background "black")
  (use-short-answers t)
  (cursor-in-non-selected-windows 'hollow)
  (cursor-type 'bar)
  (vc-follow-symlinks t)
  (native-comp-async-query-on-exit t)
  (require-final-newline t)
  (epg-pinentry-mode 'loopback)
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

  (delete-selection-mode 1)
  (repeat-mode 1)
  (global-visual-line-mode 1)
  (column-number-mode 1)
  (minibuffer-depth-indicate-mode 1)

  (setq epa-file-encrypt-to user-mail-address))

(use-package server
  :demand t
  :hook
  ;; Make sure the font is correctly loaded when running the daemon
  (server-after-make-frame . set-font-faces))

(use-package pixel-scroll
  :straight (:type built-in)
  :demand t
  :custom
  (pixel-scroll-precision-interpolation-factor 1.0)
  :bind
  (([remap scroll-up-command]   . pixel-scroll-interpolate-down)
   ([remap scroll-down-command] . pixel-scroll-interpolate-up)
   ("M-n" . pixel-scroll-up)
   ("M-p" . pixel-scroll-down))
  :hook
  (after-init . pixel-scroll-precision-mode))

(use-package sendmail
  :mode
  ("/tmp/neomutt-*" . mail-mode))

(use-package conf-mode
  :mode
  ("/etc/portage/package.*" . conf-space-mode)
  ("/etc/portage/env/*" . conf-unix-mode)
  ("/etc/portage/env/*/*" . bash-ts-mode)
  ("/etc/env.d/*" . conf-unix-mode)
  ("/etc/conf.d/*" . conf-mode))

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
  :demand t
  :custom
  (treesit-font-lock-level 4)
  :mode
  ("CMakeLists\\.txt\\'" . cmake-ts-mode)
  ("\\.cmake\\'" . cmake-ts-mode)
  :config
  (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode) t)
  (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode) t)
  (add-to-list 'major-mode-remap-alist
			   '(c-or-c++-mode . c-or-c++-ts-mode) t)
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode) t))

(use-package hl-line
  :hook (after-init . global-hl-line-mode))

(use-package cc-mode
  :unless (treesit-available-p)
  :custom
  (c-basic-offset tab-width)
  :hook
  (c-mode . (lambda ()
			  (c-set-style "linux"))))

(use-package c-ts-mode
  :after treesit
  :config
  (defun my-c-indent-style()
	`(
	  ;; Preproc directives
	  ((node-is "preproc") column-0 0)
	  ((node-is "#endif") column-0 0)
	  ((match "preproc_call" "compound_statement") column-0 0)

	  ((or (parent-is "parameter_list")
		   (parent-is "argument_list")
		   (parent-is "binary_expression")
		   (parent-is "init_declarator")
		   (parent-is "conditional_expression"))
	   parent-bol ,(* 2 c-ts-mode-indent-offset))

	  ((or (parent-is "field_declaration")
		   (parent-is "enumerator"))
	   parent-bol c-ts-mode-indent-offset)

	  ;; `{' directly under the if/for/while/switch/do if on a newline
	  ((or (match "compound_statement" "if_statement" nil nil nil)
		   (match "compound_statement" "for_statement" nil nil nil)
		   (match "compound_statement" "while_statement" nil nil nil)
		   (match "compound_statement" "switch_statement" nil nil nil)
		   (match "compound_statement" "do_statement" nil nil nil))
	   parent-bol 0)

	  ((match nil "compound_statement" "{" 0 0) parent-bol c-ts-mode-indent-offset)
										;	((match nil "compound_statement" "expression_statement") parent-bol c-ts-mode-indent-offset)

	  ;; Append here the indent style you want as base
	  ,@(alist-get 'linux (c-ts-mode--indent-styles 'c))))
  (setopt c-ts-mode-indent-style #'my-c-indent-style)
  :custom
  (c-ts-mode-indent-offset tab-width))

(use-package sh-script
  :custom
  (sh-basic-offset (/ tab-width 2))
  :hook
  (sh-mode . (lambda ()
			   (setq-local indent-tabs-mode nil))))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

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
  (load-theme 'doom-gruvbox t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))

(when (symbol-function 'malloc-trim)
  (add-hook 'post-gc-hook #'malloc-trim))

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


(use-package smex)

(use-package counsel
  :after (ivy smex)
  :demand t
  :hook
  (after-init . counsel-mode)
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

(use-package crontab-mode)

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
  :bind (("C-c v c" . magit-commit)
		 ("C-c v r c" . magit-rebase-continue)
		 ("C-c v f" . magit-stage-file))
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

(use-package yaml-mode)

(use-package eglot
  :straight (:type built-in)
  :bind ("C-c r" . eglot-rename)
  :commands eglot eglot-ensure
  :defines (eglot-auto-display-help-buffer)
  :hook (((c-mode-common
		   c-ts-base-mode
		   yaml-mode
		   yaml-ts-mode
		   python-mode
		   python-ts-mode
		   rust-ts-mode
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
  :defines (editorconfig-lisp-use-default-indent)
  :hook (after-init . editorconfig-mode)
  :config (setq editorconfig-lisp-use-default-indent t))

(use-package markdown-mode)

(use-package git-gutter
  :bind (("C-c v s" . git-gutter:stage-hunk)
		 ("C-c v n" . git-gutter:next-hunk)
		 ("C-c v p" . git-gutter:previous-hunk)
		 ("C-c v h r" . git-gutter:revert-hunk))
  :hook (after-init . global-git-gutter-mode))

(use-package flyspell
  :hook
  ((prog-mode conf-mode) . flyspell-prog-mode)
  (text-mode . flyspell-mode))

(use-package sort-words)

(use-package git-commit
  :hook
  (after-init . global-git-commit-mode)
  (git-commit-mode . (lambda () (setq fill-column 72)))
  :custom
  (git-commit-summary-max-length 50)
  (git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line)))

(use-package eldoc
  :straight (:type built-in)
  :custom
  (eldoc-echo-area-use-multiline-p 1))

(use-package clipetty
  :hook (tty-setup . global-clipetty-mode))

(use-package debbugs)

(use-package saveplace
  :hook (after-init . save-place-mode))

(use-package ebuild-mode
  :hook
  (ebuild-mode . (lambda ()
				   (setq-local indent-tabs-mode t
							   sh-basic-offset 4)))
  :bind
  ("C-c u" . ebuild-mode-all-keywords-unstable)
  :custom
  (ebuild-mode-xml-indent-tabs t))

(use-package nxml-mode
  :straight (:type built-in)
  :after (ebuild-mode)
  :hook
  (nxml-mode . (lambda ()
	(when ebuild-repo-mode
	  (setq-local indent-tabs-mode t
				  sh-basic-offset 4)))))

(use-package company-ebuild
  :after (company ebuild-mode)
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/company-ebuild.git"))

(use-package yasnippet-snippets)

(use-package yasnippet
  :after (yasnippet-snippets)
  :hook (after-init . yas-global-mode))

(use-package ivy-yasnippet
  :after (yassnippet))

(use-package elogt
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-elogt.git"))

(use-package ebuild-snippets
  :after (yasnippet)
  :hook (after-init . ebuild-snippets-initialize)
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-ebuild-snippets.git"
		 :files ("*.el" "snippets")))

(use-package eix
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-eix.git"))

(use-package openrc
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/emacs-openrc.git"))

(use-package flycheck-pkgcheck
  :straight
  (:host nil :repo "https://anongit.gentoo.org/git/proj/pkgcore/pkgcheck.git"
		 :files ("contrib/emacs/*.el")))

(use-package org
  :hook
  (variable-pitch-mode)
  :custom
  (org-ellipsis " ▾")
  (org-agenda-files '("~/org/agenda.org" "~/org/Birthdays.org.gpg"))
  (org-agenda-start-with-log-mode t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
	 (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "COMPLETED(c)" "CANC(k@)")))
  :config
  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

(use-package org-indent
  :straight (:type built-in)
  :after org
  :hook (org-mode . org-indent-mode))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode))

(use-package visual-fill-column
  :functions (visual-fill-column-mode)
  :defines
  (visual-fill-column-width
   visual-fill-column-center-text)
  :after org
  :hook (org-mode . '((lambda ()
						(setopt visual-fill-column-width 130
							   visual-fill-column-center-text t))
					  (visual-fill-column-mode 1))))

(use-package elfeed
  :defines
  (elfeed-search-feed-face
   elfeed-feeds)
  :config
  (setq elfeed-search-feed-face ":foreground #ffffff :weight bold"
        elfeed-feeds (quote
                       (("https://www.reddit.com/r/linux.rss" reddit linux)
                        ("https://www.reddit.com/r/commandline.rss" reddit commandline)
                        ("https://www.reddit.com/r/distrotube.rss" reddit distrotube)
                        ("https://www.reddit.com/r/emacs.rss" reddit emacs)
                        ("https://hackaday.com/blog/feed/" hackaday linux)
                        ("https://opensource.com/feed" opensource linux)
                        ("https://linux.softpedia.com/backend.xml" softpedia linux)
                        ("https://itsfoss.com/feed/" itsfoss linux)
                        ("https://www.zdnet.com/topic/linux/rss.xml" zdnet linux)
                        ("https://www.phoronix.com/rss.php" phoronix linux)
                        ("https://www.computerworld.com/index.rss" computerworld linux)
                        ("https://www.networkworld.com/category/linux/index.rss" networkworld linux)
                        ("https://www.techrepublic.com/rssfeeds/topic/open-source/" techrepublic linux)
                        ("http://lxer.com/module/newswire/headlines.rss" lxer linux)

						("https://gitlab.freedesktop.org/wlroots/wlroots.atom" wlroots commits)
						("https://github.com/weechat/weechat/commits/master.atom" weechat commits)
						("https://codeberg.org/dnkl/fnott.rss" fnott commits)
						("https://codeberg.org/dnkl/wbg.rss" wbg commits)
						("https://github.com/emersion/hydroxide/commits/master.atom" hydroxide commits)

						("https://git.pwmt.org/pwmt/girara/-/tags?format=atom" girara updates)
						("https://git.pwmt.org/pwmt/zathura/-/tags?format=atom" zathura updates)
						("https://github.com/weechat/weechat/releases.atom" weechat updates)
						("https://github.com/rizsotto/Bear/releases.atom" bear updates)
						("https://github.com/eza-community/eza/releases.atom" eza updates)
						("https://github.com/reujab/silver/releases.atom" silver updates)
						("https://github.com/ajeetdsouza/zoxide/releases.atom" zoxide updates)
						("https://codeberg.org/dnkl/fnott/releases.rss" fnott updates)
						("https://codeberg.org/dnkl/wbg/releases.rss" wbg updates)
						("https://github.com/natsukagami/mpd-mpris/releases.atom" mpd-mpris updates)
						("https://github.com/nukeop/nuclear/tags.atom" nuclear updates)
						("https://github.com/emersion/hydroxide/releases.atom" hydroxide updates)
						("https://github.com/coder/code-server/releases.atom" code-server updates)))))

(use-package elfeed-goodies
  :functions (elfeed-goodies/setup)
  :config
  (elfeed-goodies/setup))

(add-to-list 'display-buffer-alist
             '("\\*e?shell\\*\\|\\*terminal\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . -1) ;; -1 == L  0 == Mid 1 == R
               (window-height . 0.33) ;; take 2/3 on bottom left
               (window-parameters
                (no-delete-other-windows . nil))))
(add-to-list 'display-buffer-alist
             '("\\*\\(Backtrace\\|Compile-log\\|Messages\\|Warnings\\)\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.33)
               (window-parameters
                (no-delete-other-windows . nil))))
(add-to-list 'display-buffer-alist
             '("\\*\\([Hh]elp\\|Command History\\|command-log\\)\\*"
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 80)
               (window-parameters
                (no-delete-other-windows . nil))))
;;; init.el ends here
