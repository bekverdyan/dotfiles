# Built-in screen: brightness keys and the bar's brightness module (which
# flashes on change), and screen rotation keys
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord icons barIcon;
  cfg = config.dotfiles.laptop;

  # Set the screen brightness: `${setBrightness} 5%+`. The sysfs file is
  # root-only, so brightnessctl goes through logind. -n0 lets it reach 0%
  # (backlight off; brightness up brings it back).
  setBrightness = "${pkgs.brightnessctl}/bin/brightnessctl -q -d ${cfg.backlight} -n0 set";

  # Polybar brightness label: a sun (outline below 50%, filled from 50%) in
  # the given color, and the percentage
  brightnessLabel = color: pkgs.writeShellScript "polybar-brightness" ''
    pct=$(${pkgs.brightnessctl}/bin/brightnessctl -d ${cfg.backlight} -m | cut -d, -f4)
    pct=''${pct%\%}
    sun=(${lib.escapeShellArgs icons.brightness})
    echo "${barIcon color "\${sun[pct >= 50]}"} $pct%"
  '';
  # Brightness keys and scrolling on the bar: change the brightness, then
  # flash the polybar icon yellow (up) or red (down) for a second over IPC
  brightnessStep = pkgs.writeShellScript "brightness-step" ''
    msg=${config.services.polybar.package}/bin/polybar-msg
    flash=''${XDG_RUNTIME_DIR:-/tmp}/brightness-flash
    case $1 in
      up) ${setBrightness} 5%+; hook=1 ;;
      down) ${setBrightness} 5%-; hook=2 ;;
      *) echo "usage: brightness-step up|down" >&2; exit 1 ;;
    esac
    $msg action backlight hook $hook >/dev/null
    # Back to normal after a second, unless another press came since
    echo $$ > "$flash"
    ( sleep 1; [ "$(cat "$flash")" = $$ ] && $msg action backlight hook 0 >/dev/null ) &
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.sxhkd.keybindings = {
      # Laptop brightness keys
      "XF86MonBrightness{Up,Down}" = "${brightnessStep} {up,down}";
      # Rotate the laptop screen; restarting bspwm reruns startupPrograms, which
      # redraws the wallpaper and restarts polybar at the new size
      "super + ctrl + {Up,Left,Right,Down}" =
        "${pkgs.xrandr}/bin/xrandr --output ${cfg.display} --rotate {normal,left,right,inverted} && bspc wm -r";
    };

    # custom/ipc, so brightnessStep can flash the icon: hook 0 is the normal
    # label, 1 yellow (brightness up), 2 red (down). It updates only through
    # those hooks, i.e. the brightness keys and scrolling on it.
    services.polybar.settings."module/backlight" = {
      type = "custom/ipc";
      hook = map (color: "${brightnessLabel color}") [ nord.accent nord.yellow nord.red ];
      initial = 1; # hook 0 at start
      scroll.up = "${brightnessStep} up";
      scroll.down = "${brightnessStep} down";
    };
  };
}
