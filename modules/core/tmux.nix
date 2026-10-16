{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    prefix = "C-Space";
    escapeTime = 0; # no lag after Esc in vim
    focusEvents = true; # pass focus in/out to apps (vim autoread, Claude Code)
    mouse = true;
    plugins = [ pkgs.tmuxPlugins.nord ];
    extraConfig = ''
      set -as terminal-features ",alacritty:RGB"

      # Split panes with \ and -, in the current directory
      bind '\' split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
    '';
  };
}
