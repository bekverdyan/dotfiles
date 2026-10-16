# LightDM login screen (slick-greeter) in Nord, for hosts where LightDM is
# set up outside Home Manager (not NixOS). The greeter runs as the
# `lightdm` user and can't see the Nix profile, so `sudo lightdm-setup`
# copies the theme, cursor, font, wallpaper and config into the system.
# Rerun it after changing anything here.
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;

  slickGreeterConf = pkgs.writeText "slick-greeter.conf" ''
    [Greeter]
    background=/usr/local/share/backgrounds/login-wallpaper
    background-color=${nord.bg}
    draw-user-backgrounds=false
    draw-grid=false
    theme-name=Nordic
    icon-theme-name=Papirus-Dark
    cursor-theme-name=Nordic-cursors
    cursor-theme-size=24
    font-name=JetBrainsMono Nerd Font 11
    clock-format=%a %d %b  %H:%M
  '';
  lightdmConf = pkgs.writeText "50-home-manager.conf" ''
    [Seat:*]
    greeter-session=lightdm-slick-greeter
    user-session=bspwm
  '';
  # Starts the same ~/.xinitrc that `startx` used
  bspwmSession = pkgs.writeText "bspwm.desktop" ''
    [Desktop Entry]
    Name=bspwm
    Comment=bspwm session from Home Manager
    Exec=${config.home.homeDirectory}/.xinitrc
    Type=Application
  '';
  lightdmSetup = pkgs.writeShellScriptBin "lightdm-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    share=/usr/local/share
    font=${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono
    rm -rf $share/themes/Nordic $share/icons/Nordic-cursors
    install -d $share/themes $share/icons $share/fonts/JetBrainsMono
    cp -rL --no-preserve=mode,ownership ${pkgs.nordic}/share/themes/Nordic $share/themes/
    cp -rL --no-preserve=mode,ownership ${pkgs.nordic}/share/icons/Nordic-cursors $share/icons/
    install -m644 $font/JetBrainsMonoNerdFont-{Regular,Bold}.ttf $share/fonts/JetBrainsMono/
    fc-cache -f $share/fonts
    install -Dm644 ${config.dotfiles.wallpaper} $share/backgrounds/login-wallpaper
    install -Dm644 ${slickGreeterConf} /etc/lightdm/slick-greeter.conf
    install -Dm644 ${lightdmConf} /etc/lightdm/lightdm.conf.d/50-home-manager.conf
    install -Dm644 ${bspwmSession} /usr/share/xsessions/bspwm.desktop
    echo "LightDM is set up. Enable it with: sudo systemctl enable lightdm"
  '';
in
{
  options.dotfiles.lightdm.enable =
    lib.mkEnableOption "the LightDM login screen setup (`sudo lightdm-setup`), for hosts that aren't NixOS";

  config = lib.mkIf (config.dotfiles.desktop.enable && config.dotfiles.lightdm.enable) {
    home.packages = [
      lightdmSetup # `sudo lightdm-setup` installs the login screen
    ];
  };
}
