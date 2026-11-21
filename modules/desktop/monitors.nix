# External monitor: when one is plugged in, turn it on (preferred mode at
# its highest refresh rate) and move dotfiles.externalMonitor.desktops to
# it; when it's unplugged, bring them back to the primary screen. Run at
# login and by srandrd on every connect/disconnect.
{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.externalMonitor;
  xrandr = "${pkgs.xrandr}/bin/xrandr";
  bspc = "${pkgs.bspwm}/bin/bspc";

  monitorSetup = pkgs.writeShellScript "monitor-setup" ''
    desktops="${lib.concatStringsSep " " cfg.desktops}"
    query=$(${xrandr} --query)
    main=$(echo "$query" | awk '/ connected primary/ { print $1; exit }')
    ext=$(echo "$query" | awk -v m="$main" '/ connected/ && $1 != m { print $1; exit }')

    if [ -n "$ext" ]; then
      # Preferred mode (marked +) and the highest rate listed for it
      set -- $(echo "$query" | awk -v o="$ext" '
        $1 == o { f = 1; next }
        f && /^[^ ]/ { exit }
        f && /\+/ {
          r = 0
          for (i = 2; i <= NF; i++) { v = $i; gsub(/[*+]/, "", v); if (v + 0 > r) r = v + 0 }
          print $1, r; exit
        }')
      ${xrandr} --output "$ext" --mode "$1" --rate "$2" --${cfg.position} "$main"
      for d in $desktops; do ${bspc} desktop "$d" -m "$ext"; done
      # bspwm gives a new monitor a default desktop; drop it
      for d in $(${bspc} query -D -m "$ext" --names); do
        case " $desktops " in *" $d "*) ;; *) ${bspc} desktop "$d" -r ;; esac
      done
    else
      for d in $desktops; do ${bspc} desktop "$d" -m "$main"; done
      # Turn off outputs that were unplugged while on
      echo "$query" | awk '/ disconnected [0-9]/ { print $1 }' |
        while read -r o; do ${xrandr} --output "$o" --off; done
    fi
    ${bspc} monitor "$main" -o $(${bspc} query -D -m "$main" --names | sort -n)
    ${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${config.dotfiles.wallpaper}
  '';
in
{
  config = lib.mkIf (config.dotfiles.desktop.enable && cfg.desktops != [ ]) {
    xsession.windowManager.bspwm.startupPrograms = [ "${monitorSetup}" ];

    systemd.user.services.srandrd = {
      Unit = {
        Description = "Set up monitors when one is plugged in or out";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${pkgs.srandrd}/bin/srandrd -n ${monitorSetup}";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
