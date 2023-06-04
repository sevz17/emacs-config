;;; early-init.el -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; PERF: Garbage collection is a big contributor to startup times. This fends it
;;   off, but will be reset later by `gcmh-mode'. Not resetting it later will
;;   cause stuttering/freezes.
(setopt gc-cons-threshold most-positive-fixnum)

;; In noninteractive sessions, prioritize non-byte-compiled source files to
;; prevent the use of stale byte-code. Otherwise, it saves us a little IO time
;; to skip the mtime checks on every *.elc file.
(setq load-prefer-newer noninteractive)

;; Change `user-emacs-directory' to keep unwanted things out of ~/.config/emacs
(require 'xdg)
(setq user-emacs-directory
	  (file-name-concat (xdg-cache-home) "emacs"))

;; Avoid tangling emacs directory
(startup-redirect-eln-cache "var/eln-cache/")

;; Configure native compilation
(require 'comp)
(setopt native-comp-speed 3
		;; Silence native comp warnings
		native-comp-async-report-warnings-errors 'silent)
(setq comp-num-cpus (num-processors)
	  native-comp-jit-compilation t)
;;; early-init.el ends here
