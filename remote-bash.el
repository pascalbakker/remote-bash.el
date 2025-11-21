;;; remote-bash.el --- Remote Bash helper functions -*- lexical-binding: t -*-
;; Author: Pascal Bakker
;; Created: 2025-11-21
;; Description: Async remote Bash execution with SSH and Tramp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

(require 'ansi-color)

(defun remote-bash--build-default-dir (remote-username remote-host remote-path)
  "Takes params and converts into ssh format"
  (format "/ssh:%s@%s:%s" remote-username remote-host remote-path))

(defun remote-bash--can-ssh-connect? (username host &optional timeout-seconds)
  (eq 0 (call-process "ssh" nil nil nil
                      "-o" "BatchMode=yes"
                      "-o" (format "ConnectTimeout=%d" (or timeout-seconds 2))
                      (format "%s@%s" username host)
                      "exit")))

(defun remote-bash--load-bash-into-string (bash-script-path)
  "Takes a bash file and returns its contents"
  (with-temp-buffer
    (insert-file-contents bash-script-path)
    (buffer-string)))

(defun remote-bash--format-bash-output-to-ansi-color (process event buf)
  "Converts ugly hex output to clean color coded output"
  (when (string= event "finished\n")
    (with-current-buffer (process-buffer process)
      (ansi-color-apply-on-region (point-min) (point-max))
      (redisplay)
      (force-window-update (get-buffer buf)))))

(defun remote-bash--wrap-command-in-output (command output-path)
  "If output path is given append output piping to bash command"
  (if output-path
      (concat "("
              command
              ") 2>&1 | tee "
              output-path)
    command))

(defun remote-bash--create-remote-command (&rest args)
  "Return a Bash command string, either from :command or :bash-path, optionally piping output to :output-path."
  (remote-bash--wrap-command-in-output
   (or
    (plist-get args :command)
    (remote-bash--load-bash-into-string (plist-get args :bash-path)))
   (plist-get args :output-path)))

(defun execute-bash-remote (&rest args)
  "Execute a Bash command or script asynchronously on a remote SSH host.

ARGS is a plist supporting the following keys:
  :username            - SSH username (required)
  :remote-device-name  - Hostname or IP of the remote machine (required)
  :path                - Remote working directory (defaults to \"~\")
  :command             - Bash command to execute
  :bash-path           - Path to Bash script on local machine (alternative to :command)
  :buffer-name         - Name for the output buffer (defaults to \"remote-shell-output\")
  :output-path         - Optional remote path to save stdout/stderr
  :show-new-window     - If t, opens buffer in new window (default t)
  :test-connection     - If t, test SSH connection before running (default nil)

The command is executed asynchronously using `start-file-process`. 
Output is collected in a buffer and ANSI color codes are applied when finished."
  (let* ((bash-remote-path (or (plist-get args :path) "~"))
         (bash-remote-command (apply #'remote-bash--create-remote-command args))
         (bash-remote-buffer-name (or (plist-get args :buffer-name) "remote-shell-output"))
         (bash-remote-remote-device (plist-get args :remote-device-name))
         (bash-remote-username (plist-get args :username))
         (bash-remote-test-connection? (or (plist-get args :test-connection) nil))
         (bash-remote-show-new-window (or (plist-get args :show-new-window) t))
         (bash-remote-buf (get-buffer-create bash-remote-buffer-name))
         (default-directory (remote-bash--build-default-dir bash-remote-username bash-remote-remote-device bash-remote-path))
         )
    ;; Test connection before executing remote. By default skips unless :test-connection t
    (if (and bash-remote-test-connection? (not (remote-bash--can-ssh-connect? bash-remote-username bash-remote-remote-device)))
        (user-error (format "Timeout: cannot connect via ssh with %s@%s" bash-remote-username bash-remote-remote-device))
      (if (not bash-remote-command)
          (message "No :command or :bash-path given.")
        (progn
          (with-current-buffer bash-remote-buf
            (erase-buffer))
          ;; Execute bash-remote-command
          (let ((proc (start-file-process
                       bash-remote-buffer-name
                       nil
                       "bash"
                       "-c"
                       bash-remote-command)))
            (set-process-buffer proc bash-remote-buf)
            ;; Create new window
            (when bash-remote-show-new-window
              (let ((new-win (split-window-right)))
                (set-window-buffer new-win bash-remote-buf)
                (select-window new-win)))
            ;; Format output when complete
            (set-process-sentinel
             proc
             (lambda (process event)
               (remote-bash--format-bash-output-to-ansi process event bash-remote-buf)))))))))

