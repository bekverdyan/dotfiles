# sxhkd: window manager, launcher, volume and screenshot keys. Feature
# keys live with their feature (network.nix, visualizers.nix,
# ../laptop/screen.nix); every module adds to services.sxhkd.keybindings.
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    services.sxhkd = {
      enable = true;
      keybindings = {
        "super + Return" = "alacritty -e tmux"; # new tmux session per terminal
        "super + space" = "rofi -show drun";
        "super + b" = "firefox";
        "super + Escape" = "pkill -USR1 -x sxhkd"; # reload keybindings
        "super + alt + {q,r}" = "bspc {quit,wm -r}"; # quit / restart bspwm
        "super + alt + l" = "loginctl lock-session"; # blurlock
        "super + {_,shift + }w" = "bspc node -{c,k}"; # close / kill window
        "super + m" = "bspc desktop -l next"; # toggle fullscreen-like monocle
        "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseudo_tiled,floating,fullscreen}";
        "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";
        # Resize: grow / shrink the window on the H/J/K/L side by 20 px (a
        # tiled window moves the split with its neighbor there)
        "super + ctrl + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";
        "super + ctrl + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";
        "super + {_,shift + }{1-9,0}" = "bspc {desktop -f,node -d} '^{1-9,10}'";
        # Volume keys; -l 1.0 caps the volume at 100%
        "XF86Audio{Raise,Lower}Volume" =
          "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%{+,-}";
        "XF86AudioMute" = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        # Screenshot to the clipboard, ready to paste (no file): whole screen /
        # a dragged area or clicked window, with a Nord frost selection. Two
        # bindings, since sxhkd's {a,b} would split maim's r,g,b color
        "Print" = "${pkgs.maim}/bin/maim -u | ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png";
        "shift + Print" =
          let
            # maim wants the selection color as r,g,b in 0-1
            rgb = hex: lib.concatMapStringsSep ","
              (i: toString (lib.fromHexString (builtins.substring i 2 hex) / 255.0)) [ 1 3 5 ];
          in
          "${pkgs.maim}/bin/maim -u -s -b 2 -c ${rgb nord.accent} | ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png";
      };
    };

    # Reload the running sxhkd when switch changes its bindings (also when a
    # script a binding runs moves to a new store path); otherwise it keeps
    # running the old commands until the next login
    xdg.configFile."sxhkd/sxhkdrc".onChange = "${pkgs.procps}/bin/pkill -USR1 -x sxhkd || true";
  };
}
