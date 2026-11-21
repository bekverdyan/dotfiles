# The X11 desktop: bspwm with sxhkd keys, polybar, rofi, Alacritty, the
# Nord theme, and the apps and menus around them. Linux with X11 only; a
# host turns it on with dotfiles.desktop.enable.
{ config, lib, pkgs, ... }:
{
  imports = [
    ./theme.nix
    ./xsession.nix
    ./keys.nix
    ./bar.nix
    ./apps.nix
    ./network.nix
    ./monitors.nix
    ./visualizers.nix
    ./real-size.nix
    ./login.nix
  ];

  options.dotfiles = {
    desktop.enable = lib.mkEnableOption "the X11 desktop (bspwm, sxhkd, polybar, rofi, theme, apps)";

    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
      defaultText = lib.literalExpression "pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath";
      example = lib.literalExpression ''"''${config.home.homeDirectory}/Pictures/wallpaper.jpg"'';
      description = "Wallpaper of the desktop and the login screen.";
    };

    externalMonitor = {
      desktops = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "9" "10" ];
        description = "Desktops moved to an external monitor while one is connected.";
      };
      position = lib.mkOption {
        type = lib.types.enum [ "left-of" "right-of" "above" "below" ];
        default = "right-of";
        description = "Where the external monitor sits, relative to the primary screen.";
      };
    };
  };

  config = lib.mkIf config.dotfiles.desktop.enable {
    home.sessionVariables = {
      TERMINAL = "alacritty";
      BROWSER = "firefox";
    };
  };
}
