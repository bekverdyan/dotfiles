# Options
set -g status-interval 1
set -g status on

# Colors

# Status bar
set -g status-style fg=white,bg=black

# Panes
set -g pane-border-style fg=black,bg=black
set -g pane-active-border-style fg=brightblack,bg=black
set -g display-panes-colour black
set -g display-panes-active-colour brightblack

# Clock Mode

setw -g clock-mode-colour cyan

# Messages

set -g message-style fg=cyan,bg=brightblack
set -g message-command-style fg=cyan,bg=brightblack

# Content

# Layout
set -g status-justify left

# Left
set -g status-left "" # "#[fg=black,bg=blue,bold] #S "
set -g status-right "#{prefix_highlight}"
# set -g status-right "#{prefix_highlight} #[fg=cyan,bg=brightblack,nobold,noitalics,nounderscore] #[fg=black,bg=cyan,bold] #H "

#+--- Windows ---+
set -g window-status-format "#[fg=brightblue,bg=black] #[noitalics]#W "
set -g window-status-current-format "#[fg=black,bg=brightcyan] #[fg=black,bg=brightcyan]#W "
set -g window-status-separator " "

# Plugin support

set -g @prefix_highlight_fg black
set -g @prefix_highlight_bg brightcyan

set -g @prefix_highlight_prefix_prompt '^-'
set -g @prefix_highlight_copy_mode_attr "fg=black,bg=brightcyan"

# vim: ft=tmux
