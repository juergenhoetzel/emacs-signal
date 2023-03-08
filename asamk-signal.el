;;; asamk-signal.el --- Emacs bindings for signal-cli dbus api  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; Keywords: comm
;; Version:    1.0.0-snapshot
;; Homepage:   https://github.com/juergenhoetzel/emacs-signal
;; Package-Requires: ((emacs "27.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an access to the signal-cli DBUS API
;; <https://github.com/AsamK/signal-cli/blob/master/man/signal-cli-dbus.5.adoc>

;; In order to use this package, you must ensure the signal-cli daemon is running:
;;
;; # signal-cli daemon
;;; Code:

(require 'dbus)
(require 'cl-lib)

(defconst asamk-signal-service "org.asamk.Signal"
  "The D-Bus name used to talk to Secret Service.")

(defconst asamk-signal-path "/org/asamk/Signal"
  "The D-Bus root object path used to talk to Secret Service.")

(defvar asamk-signal--message-receivedv2-handler-object  nil
  "Dbus registration object for `asamk-signal--message-receivedv2-handler'.")

(cl-defstruct asamk-signal-message
  (timestamp :read-only t)
  (sender :read-only t)
  (group-id :read-only t)
  (text :read-only t)
  (extras :read-only t))

(defvar asamk-signal-messages nil
  "List of messages received (in chronological descending order).")

(defun asamk-signal--message-receivedv2-handler (timestamp sender group-id text extras)
  "Dbus signal handler for incoming messages."
  (let ((message (make-asamk-signal-message
		  :timestamp timestamp
		  :sender sender
		  :group-id group-id
		  :text text
		  :extras extras)))
    (add-to-list 'asamk-signal-messages message)))

(defun asamk-signal ()
  "FIXME: Implement chat-view"
  (interactive)
  (unless asamk-signal--message-receivedv2-handler-object
    (setq asamk-signal--message-receivedv2-handler-object
	  (dbus-register-signal :session asamk-signal-service a asamk-signal-service  "MessageReceivedV2" #'asamk-signal--message-receivedv2-handler)))
  (dolist (message asamk-signal-messages)
    (message "From %s: %s" (asamk-signal-message-sender message) (asamk-signal-message-text message))))

(defun asamk-signal-available-p ()
  "Return t if signal dbus API is available."
  (dbus-ping :session asamk-signal-service))

(defun asamk-signal-get-accounts ()
  "Return list of accounts as D-Bus object paths."
  (dbus-call-method :session asamk-signal-service asamk-signal-path "org.asamk.SignalControl" "listAccounts"))

(defun asamk-signal-account-get-devices (object-path)
  "Return list of devices for account at OBJECT-PATH."
  (dbus-call-method :session asamk-signal-service object-path asamk-signal-service "listDevices"))

(defun asamk-signal-account-get-selfnumber (object-path)
  "Return own number for account at OBJECT-PATH."
  (dbus-call-method :session asamk-signal-service object-path asamk-signal-service "getSelfNumber"))

(defun asamk-signal-account-get-numbers (object-path)
  "Return list of all known numbers for account at OBJECT-PATH."
  (dbus-call-method :session asamk-signal-service object-path asamk-signal-service "listNumbers"))

(defun asamk-signal-account-send-message (object-path number-or-numbers message &rest attachements)
  "Sends a MESSAGE to NUMBER-OR-NUMBERS with ATTACHEMENTS.

Use account at OBJECT-PATH.  ATTACHEMENT is expected to be a list of filenames."
  (dbus-call-method :session asamk-signal-service object-path asamk-signal-service "sendMessage" message attachements number-or-numbers))

(provide 'asamk-signal)
;;; asamk-signal.el ends here
