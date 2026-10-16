{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    plugins = [ pkgs.vimPlugins.nord-vim ];
    extraConfig = ''
      syntax on
      colorscheme nord
    '';
  };
}
