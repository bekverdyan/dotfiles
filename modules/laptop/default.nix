# Laptop parts: battery and brightness in the bar, brightness keys, screen
# rotation, and Dell firmware charge limits. They add to the desktop
# (polybar, sxhkd), so they need dotfiles.desktop.enable as well. The names
# below differ between laptops; check them with `ls /sys/class/power_supply`,
# `ls /sys/class/backlight` and `xrandr`.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./battery.nix
    ./screen.nix
    ./dell-charge-limits.nix
  ];

  options.dotfiles.laptop = {
    enable = lib.mkEnableOption "the laptop parts (battery, brightness, screen rotation)";

    battery = mkOption {
      type = types.str;
      default = "BAT0";
      description = "Battery, under /sys/class/power_supply.";
    };
    adapter = mkOption {
      type = types.str;
      default = "AC";
      description = "Charger (AC adapter), under /sys/class/power_supply.";
    };
    backlight = mkOption {
      type = types.str;
      default = "intel_backlight";
      description = "Screen backlight, under /sys/class/backlight.";
    };
    display = mkOption {
      type = types.str;
      default = "eDP-1";
      description = "Built-in screen's xrandr output, rotated by Super+Ctrl+arrows.";
    };
  };
}
