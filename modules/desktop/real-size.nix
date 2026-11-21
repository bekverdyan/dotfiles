# Super+E: the focused Android emulator at a real screen's size (a car's
# 15.6" by default), floating at the top left; again puts it back as it
# was. For judging an app's sizes on this laptop's screen as on the device.
{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.realSize;
  bspc = "${pkgs.bspwm}/bin/bspc";
  xdotool = "${pkgs.xdotool}/bin/xdotool";
  xprop = "${pkgs.xprop}/bin/xprop";
  xrandr = "${pkgs.xrandr}/bin/xrandr";

  realSize = pkgs.writeShellScript "real-size" ''
    win=$(${bspc} query -N -n focused.window) || exit 0
    # Only the emulator's screen window (its toolbar is another window)
    ${xprop} -id "$win" WM_NAME | grep -q '"Android Emulator' || exit 0
    state="''${XDG_RUNTIME_DIR:-/tmp}/real-size-$win"

    if [ -f "$state" ]; then
      # Back: the window's earlier state, and its place if it floated
      read -r was x y w h < "$state"
      rm -f "$state"
      ${bspc} node "$win" -t "$was"
      [ "$was" = floating ] && ${xdotool} windowsize "$win" "$w" "$h" windowmove "$win" "$x" "$y"
      exit 0
    fi

    eval "$(${xdotool} getwindowgeometry --shell "$win")" # X Y WIDTH HEIGHT
    was=$(${bspc} query -T -n "$win" | grep -o '"state":"[a-z_]*"' | head -1 | cut -d'"' -f4)
    echo "$was $X $Y $WIDTH $HEIGHT" > "$state"

    # Pixels per mm of the primary screen, from xrandr's "1920x1080+0+0 ... 381mm x 214mm"
    read -r px mm < <(${xrandr} --query | awk '/ connected primary/ {
      split($4, g, "x"); sub("mm", "", $(NF-2)); print g[1], $(NF-2) }')
    # The diagonal in the screen's proportions
    read -r nw nh < <(awk -v d=${toString cfg.inches} -v w=${toString (builtins.elemAt cfg.ratio 0)} -v h=${toString (builtins.elemAt cfg.ratio 1)} -v px="$px" -v mm="$mm" 'BEGIN {
      k = d * 25.4 / sqrt(w * w + h * h) * px / mm
      printf "%d %d\n", w * k + .5, h * k + .5 }')
    ${bspc} node "$win" -t floating
    ${xdotool} windowsize "$win" "$nw" "$nh" windowmove "$win" 0 0
  '';
in
{
  options.dotfiles.realSize = {
    inches = lib.mkOption {
      type = lib.types.number;
      default = 15.6;
      description = "Diagonal of the screen Super+E shows the emulator at (a BYD Song Plus's 15.6\").";
    };
    ratio = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [ 16 9 ];
      description = "That screen's width and height ratio, as the emulator's window shows it.";
    };
  };

  config = lib.mkIf config.dotfiles.desktop.enable {
    services.sxhkd.keybindings."super + e" = "${realSize}";
  };
}
