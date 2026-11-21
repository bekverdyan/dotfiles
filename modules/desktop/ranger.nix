# Image previews in ranger. Alacritty has no image protocol, so ueberzug
# (ueberzugpp's compatible `ueberzug`) draws them as an X window over it.
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    programs.ranger = {
      extraPackages = [ pkgs.ueberzugpp ];
      settings = {
        preview_images = true;
        preview_images_method = "ueberzug";
      };
    };
  };
}
