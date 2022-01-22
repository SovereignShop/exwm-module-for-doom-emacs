;;; os/exwm/config.el -*- lexical-binding: t; -*-

(add-hook 'exwm-update-title-hook #'+exwm-rename-buffer-to-title)

(use-package! exwm
  :config
  (use-package! exwm-randr
    :config
    (exwm-randr-enable))

  (use-package! exwm-systemtray
    :config
    (exwm-systemtray-enable))

  ;; A few `ido' fixes.
  (use-package! exwm-config
    :config
    (exwm-config--fix/ido-buffer-window-other-frame))

  ;; Configure emacs input methods in all X windows.
  (use-package! exwm-xim
    :config
    ;; These variables are required for X programs to connect with XIM.
    (setenv "XMODIFIERS" "@im=exwm-xim")
    (setenv "GTK_IM_MODULE" "xim")
    (setenv "QT_IM_MODULE" "xim")
    (setenv "CLUTTER_IM_MODULE" "xim")
    (setenv "QT_QPA_PLATFORM" "xcb")
    (setenv "SDL_VIDEODRIVER" "x11")
    (exwm-xim-enable))

  ;; Do not show warnings when a window manager is already running.
  (advice-add #'exwm-init :around
              (defun +ignore-warnings-a (oldfun &rest args)
                (cl-letf (((symbol-function #'warn) (symbol-function #'ignore)))
                  (apply oldfun args))))

  (exwm-enable)

  ;; Prevent EXWM buffers from changing their name while not focused.
  ;; This allows Persp to restore them as intended.
  (when (featurep! :ui workspaces)
    (advice-add #'exwm--update-utf8-title :around
                #'exwm--update-utf8-title-advice))

  ;; For some reason, after switching workspaces, input focus is not updated.
  ;; HACK This uses a mouse click to regain focus.
  (advice-add #'+workspace-switch :after #'+exwm-refocus-application)

  ;; Show EXWM buffers in buffer switching prompts.
  (add-hook 'exwm-mode-hook #'doom-mark-buffer-as-real-h)

  (map! :leader
        :desc "Open a GNU/Linux application" "$" #'app-launcher-run-app))


(cl-pushnew ?\C-c exwm-input-prefix-keys)
(map! :map exwm-mode-map
      :prefix "C-c"
      ;; We also set up a separate general way to send prefix keys to our
      ;; application.
      :desc "Send the next key" "C-q" #'exwm-input-send-next-key)

(use-package exwm-evil
  :when (featurep! :editor evil)
  :after exwm
  :config
  (exwm-evil-enable-mouse-workaround)
  (add-hook 'exwm-manage-finish-hook 'exwm-evil-mode)
  (cl-pushnew 'escape exwm-input-prefix-keys))

(use-package! exwm-firefox-evil
  :when (featurep! :editor evil)
  :after exwm
  :config
  (cl-pushnew 'escape exwm-input-prefix-keys)
  ;; We can use VIM keys with any browser that has compatible keybindings.
  (cl-loop for class in '("firefoxdeveloperedition"
                          "\"firefoxdeveloperedition\""
                          "IceCat"
                          "chromium-browser"
                          "Google-chrome"
                          "Google-chrome-unstable")
           do (cl-pushnew class exwm-firefox-evil-firefox-class-name
                          :test #'string=))

  (add-hook 'exwm-manage-finish-hook 'exwm-firefox-evil-activate-if-firefox)
  (map! :map exwm-firefox-evil-mode-map
        :n "f" #'exwm-firefox-core-hint-links ; Requires Link Hints add-on.
        :n "F" #'exwm-firefox-core-hint-links-new-tab-and-switch
        :n "u" #'exwm-firefox-core-tab-close-undo
        :n "U" #'exwm-firefox-core-undo
        :n "/" #'exwm-firefox-core-find ; Compatible with Chrome as well.
        :n [remap exwm-firefox-core-cancel] #'+exwm-firefox-core-cancel
        :after exwm-evil
        ;; These are mroe in line with Evil than the default
        :n "g0" #'exwm-firefox-core-tab-first
        :n "g$" #'exwm-firefox-core-tab-last
        :n "0"  #'exwm-evil-core-beginning-of-line
        :n "$"  #'exwm-evil-core-end-of-line
        ;; This way we can use prefix arguments with these commands.
        :n "j" #'exwm-evil-core-down
        :n "k" #'exwm-evil-core-up
        :n "h" #'exwm-evil-core-left
        :n "l" #'exwm-evil-core-right
        ;; Add zoom commands
        :n "+" #'exwm-evil-core-zoom-in
        :n "-" #'exwm-evil-core-zoom-out
        :n "=" #'exwm-evil-core-reset-zoom))

(use-package! exwm-edit
  :after exwm
  :config
  (setq exwm-edit-split "below")
  (add-hook! '(exwm-edit-before-finish-hook
               exwm-edit-before-cancel-hook)
    (defun exwm-edit-clear-last-kill ()
      (setq exwm-edit-last-kill nil)))
  (add-hook 'exwm-edit-compose-hook #'+exwm-edit-activate-appropriate-major-mode))

(use-package! exwm-mff
  :hook (exwm-init . exwm-mff-mode))

(after! helm
  ;; Using `helm-display-buffer-in-own-frame' causes EXWM to emit an error.
  (when (eq helm-default-display-buffer-functions
            #'helm-display-buffer-in-own-frame)
    (setq helm-default-prompt-display-function #'helm-default-display-buffer)))
