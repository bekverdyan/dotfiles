# X session and screen lock. Home Manager writes ~/.xinitrc, which starts
# bspwm; the login screen (login.nix) runs it.
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;

  # Manjaro-style blurlock: a blurred screenshot of the desktop behind i3lock.
  # i3lock comes from pacman (`sudo pacman -S i3lock`): a Nix-built one can't
  # check passwords on Arch, since PAM needs the host's setuid helper.
  blurlock = pkgs.writeShellScriptBin "blurlock" ''
    img="''${XDG_RUNTIME_DIR:-/tmp}/blurlock.png"
    ${pkgs.imagemagick}/bin/magick x:root -scale 20% -blur 0x2.5 -resize 500% -depth 8 "$img"
    # -n stays in the foreground so xss-lock knows when it's unlocked
    /usr/bin/i3lock -n -e -f -c ${builtins.substring 1 6 nord.bg} -i "$img" "$@"
    status=$?
    rm -f "$img"
    exit $status
  '';
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [
      pkgs.feh # wallpaper
      blurlock # lock the screen (also Super+Alt+L)
    ];

    xsession = {
      enable = true;
      scriptPath = ".xinitrc";

      windowManager.bspwm = {
        enable = true;
        extraConfigEarly = "bspc monitor -d 1 2 3 4 5 6 7 8 9 10";
        settings = {
          border_width = 2;
          window_gap = 10;
          split_ratio = 0.52;
          borderless_monocle = true;
          gapless_monocle = true;
          focused_border_color = nord.accent;
          normal_border_color = nord.bgAlt;
        };
        startupPrograms = [
          # US, Armenian (phonetic-alt: 8 is Ր, R is Ռ) and Russian (phonetic)
          # layouts, cycled with Alt+Shift; Caps Lock acts as Esc. The bar's
          # flags for them are in bar.nix (layoutFlags).
          "${pkgs.setxkbmap}/bin/setxkbmap -layout us,am,ru -variant ,phonetic-alt,phonetic -option grp:alt_shift_toggle,caps:escape"
          "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${config.dotfiles.wallpaper}"
          # Restart the bar once bspwm runs, so the desktop list connects
          "systemctl --user restart polybar"
        ];
      };
    };

    # xss-lock runs blurlock after 10 idle minutes and before suspend.
    # Super+Alt+L locks through logind, so only one locker ever runs.
    services.screen-locker = {
      enable = true;
      lockCmd = "${blurlock}/bin/blurlock";
      inactiveInterval = 10;
      xautolock.enable = false; # the X screensaver timer is enough
    };
  };
}
