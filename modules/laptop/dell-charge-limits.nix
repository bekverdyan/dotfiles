# Battery charge limits, kept by the Dell firmware (dell_laptop driver):
# charging stops at `end` and starts again below `start`. Dell allows
# start 50-95 and end 55-100, at least 5 apart. Writing needs root, so
# `sudo battery-setup` applies them and installs a tmpfiles rule that
# reapplies them at boot. Rerun it after changing them. `sudo battery-full`
# sets 95-100 to charge to full until the next boot (or `sudo battery-setup`).
{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.laptop;
  limits = cfg.dellChargeLimits;
  bat = "/sys/class/power_supply/${cfg.battery}";

  # The stop must stay at least 5 above the start, so the order of writes
  # matters. At boot, start goes first: that lowers a leftover battery-full
  # 95-100 before the stop comes down. Then Custom mode, so the firmware
  # uses the thresholds
  batteryTmpfiles = pkgs.writeText "battery-charge.conf" ''
    w ${bat}/charge_control_start_threshold - - - - ${toString limits.start}
    w ${bat}/charge_control_end_threshold - - - - ${toString limits.end}
    w ${bat}/charge_types - - - - Custom
  '';
  batterySetup = pkgs.writeShellScriptBin "battery-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    install -Dm644 ${batteryTmpfiles} /etc/tmpfiles.d/battery-charge.conf
    cd ${bat}
    # Start at the minimum first, so any new pair can be written after it
    echo 50 > charge_control_start_threshold
    echo ${toString limits.end} > charge_control_end_threshold
    echo ${toString limits.start} > charge_control_start_threshold
    echo Custom > charge_types
    echo "Charge from $(cat charge_control_start_threshold)% to $(cat charge_control_end_threshold)%, mode: $(cat charge_types)"
  '';
  # Charging only begins below the start, so lift both (the highest Dell
  # allows) to charge now, even from 76-80%
  batteryFull = pkgs.writeShellScriptBin "battery-full" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    cd ${bat}
    echo 100 > charge_control_end_threshold
    echo 95 > charge_control_start_threshold
    echo "Charging to 100% until reboot; battery-setup restores ${toString limits.start}-${toString limits.end}%"
  '';
in
{
  options.dotfiles.laptop.dellChargeLimits = {
    enable = lib.mkEnableOption "Dell firmware battery charge limits (battery-setup, battery-full)";
    start = lib.mkOption {
      type = lib.types.ints.between 50 95;
      default = 75;
      description = "Charging starts again below this percentage.";
    };
    end = lib.mkOption {
      type = lib.types.ints.between 55 100;
      default = 80;
      description = "Charging stops at this percentage; at least start + 5.";
    };
  };

  config = lib.mkIf (cfg.enable && limits.enable) {
    assertions = [{
      assertion = limits.end >= limits.start + 5;
      message = "dotfiles.laptop.dellChargeLimits: end must be at least start + 5";
    }];

    home.packages = [
      batterySetup # `sudo battery-setup` sets the battery charge limits
      batteryFull # `sudo battery-full` charges to 100% once, e.g. before a trip
    ];

    # Full store paths: sudo doesn't search the Nix profile
    home.shellAliases = {
      battery-setup = "sudo ${batterySetup}/bin/battery-setup";
      battery-full = "sudo ${batteryFull}/bin/battery-full";
    };
  };
}
