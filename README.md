# Remote-bash.el - Remote Shell Execution Tool for Emacs

remote-bash.el is an Emacs Lisp library for executing Bash commands asynchronously on remote machines over SSH using Tramp. It simplifies running remote builds, scripts, and tasks directly from Emacs without blocking the editor.

Example:
```elisp
  (execute-bash-remote
   :username "alonzo"
   :remote-device-name "lambda-calculus-777.com"
   :command "ls -l"
   :buffer-name "*result buffer*")
```

## Usage

```
Execute a Bash command or script asynchronously on a remote SSH host.

ARGS is a plist supporting the following keys:
  :username            - (Required) SSH username 
  :remote-device-name  - Hostname or IP of the remote machine
  :path                - (Optional) Remote working directory (defaults to \"~\")
  :command             - (Required or :bash-path) Bash command to execute
  :bash-path           - (Required or :command) Path to Bash script on local machine (alternative to :command)
  :buffer-name         - (Required) Name for the output buffer (defaults to \"remote-shell-output\")
  :output-path         - (Optional) remote path to save stdout/stderr
  :show-new-window     - (Optional) If t, opens buffer in new window (default t)
  :test-connection     - (Optional) If t, test SSH connection before running (default nil)

The command is executed asynchronously using `start-file-process`. 
Output is collected in a buffer and ANSI color codes are applied when finished.
```

Below is a minimal execution. By default it will execute in the home folder with the default shell of the system. 

```elisp
  (execute-bash-remote
   :username "[USERNAME]"
   :remote-device-name "[HOST-NAME]"
   :command "ls -l"
   :buffer-name "[OUTPUT BUFFER NAME]")
```

To execute a remote command use the 'command' key

```elisp
  (execute-bash-remote
   :username "[USERNAME]"
   :remote-device-name "[HOST-NAME]"
   :path "~/code-folder"
   :command "[SHELL COMMAND]"
   :buffer-name "[OUTPUT BUFFER NAME]"
   :output-path "[REMOTE OUTPUT TEXT FILE]"
   :show-new-window t
   :test-connection t)
```

To execute a local bash script on the remote use the 'bash-path' key. You must either use :command or :bash-path

```elisp
  (execute-bash-remote
   :username "[USERNAME]"
   :remote-device-name "[HOST-NAME]"
   :bash-path "[SHELL COMMAND]"
   :buffer-name "[OUTPUT BUFFER NAME]")
```

If you want to test a connection add 'test-connection t'. By default it will not do a precheck.

## Installation

Just drop this file in your config

```elisp
(load-file "remote-bash.el")
```

## Notes

By default it will open a new buffer to the right and output the results. To change the behavoir of how the is opened or managed, change this code to your liking:

```elisp
(when bash-remote-show-new-window
  (let ((new-win (split-window-right)))
    (set-window-buffer new-win bash-remote-buf)
    (select-window new-win)))
```

## TODO

- Apply ANSI colors by chunk instead of after the execution was complete
- Modify to use TRAMP instead of start-file-process for singular ssh connection
- Enable different shells
