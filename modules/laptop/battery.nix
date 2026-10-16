# Battery in the bar
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord icons barIcon;
  cfg = config.dotfiles.laptop;

  # Polybar battery label: a level icon on battery, a green charging icon
  # while charging, a plug when plugged in but not charging (held by the
  # limits, or full), and a yellow alert at 10% or less. Two Dell quirks:
  # - above the stop limit (e.g. after battery-full) the firmware runs the
  #   laptop from the battery, charger plugged in, down to the start limit:
  #   a dimmed plug with "draining" (status Discharging while AC is online);
  # - after that it can stay in "Charging" while letting only ~50 mA in, so
  #   the battery still drains under load until the charger is re-plugged:
  #   a yellow plug with "replug" when charging below 200 mA. Under 90% only,
  #   since the current legitimately tapers off near full.
  batteryStatus = pkgs.writeShellScript "polybar-battery" ''
    bat=/sys/class/power_supply/${cfg.battery}
    read -r status < $bat/status
    read -r pct < $bat/capacity
    read -r ac < /sys/class/power_supply/${cfg.adapter}/online
    # current_now briefly fails ("No such device") on some reads
    ma=$(( $(cat $bat/current_now 2>/dev/null || echo -1000) / 1000 ))
    level=(${lib.escapeShellArgs icons.battery})
    charging=(${lib.escapeShellArgs icons.batteryCharging})
    i=$(( (pct + 5) / 10 )); (( i < 1 )) && i=1; (( i > 10 )) && i=10
    case $status in
      Charging)
        if (( ma >= 0 && ma < 200 && pct < 90 )); then
          echo "${barIcon nord.yellow icons.plug} %{F${nord.yellow}}$pct% replug%{F-}"
        else echo "${barIcon nord.green "\${charging[i-1]}"} $pct%"; fi ;;
      Discharging)
        if (( ac == 1 )); then echo "${barIcon nord.muted icons.plug} %{F${nord.muted}}$pct% draining%{F-}"
        elif (( pct <= 10 )); then echo "${barIcon nord.yellow icons.batteryAlert} %{F${nord.yellow}}$pct%%{F-}"
        else echo "${barIcon nord.accent "\${level[i-1]}"} $pct%"; fi ;;
      *) echo "${barIcon nord.accent icons.plug} $pct%" ;; # "Not charging", "Full"
    esac
  '';
in
{
  config = lib.mkIf cfg.enable {
    # A script, since internal/battery shows "Not charging" (plugged in,
    # held by the charge limits) as discharging
    services.polybar.settings."module/battery" = {
      type = "custom/script";
      exec = batteryStatus;
      interval = 5;
    };
  };
}
