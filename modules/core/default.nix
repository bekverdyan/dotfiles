# What works on any machine with Nix (any Linux, NixOS, macOS): shells and
# prompt, CLI tools, tmux, vim, git. Nothing here needs a desktop or
# particular hardware.
{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./tmux.nix
    ./vim.nix
    ./git.nix
  ];

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop
    gtop # system monitor dashboard
    gotop # system monitor, Nord colors (config below)
    fff # minimal file manager (`f` cds into the dir you quit in)
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables.EDITOR = "vim";

  # gotop: unset keys keep its defaults
  xdg.configFile."gotop/gotop.conf".text = ''
    colorscheme=nord
  '';
}
