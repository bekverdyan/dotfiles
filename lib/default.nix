# Values shared by the modules. Use it with:
#   let inherit (import ../../lib { inherit lib; }) nord icons barIcon; in ...
{ lib }:
rec {
  # Nord colors, shared by bspwm borders, polybar, rofi, fzf, cava, ...
  nord = {
    bg = "#2e3440";
    bgAlt = "#3b4252";
    bgHi = "#434c5e";
    fg = "#d8dee9";
    muted = "#4c566a";
    accent = "#88c0d0";
    red = "#bf616a";
    orange = "#d08770"; # nord12
    yellow = "#ebcb8b";
    green = "#a3be8c";
    frost1 = "#8fbcbb"; # nord7 (accent is nord8)
    frost3 = "#81a1c1"; # nord9
    frost4 = "#5e81ac"; # nord10
    pink = "#b48ead"; # nord15, Aurora purple
  };

  # A character from its code point (Nix strings have no \u escape). Above
  # U+FFFF it goes through a JSON surrogate pair.
  char = code:
    let
      hex4 = n: lib.fixedWidthString 4 "0" (lib.toHexString n);
      c = code - 65536;
    in builtins.fromJSON (if code < 65536 then ''"\u${hex4 code}"''
      else ''"\u${hex4 (55296 + c / 1024)}\u${hex4 (56320 + lib.mod c 1024)}"'');

  # Polybar icons: Material Design glyphs of the JetBrainsMono Nerd Font, by
  # code point (look names up at nerdfonts.com/cheat-sheet)
  md = hex: char (lib.fromHexString hex);
  icons = {
    # md-weather_sunny (outline) below 50%, md-white_balance_sunny (filled) above
    brightness = map md [ "f0599" "f05a8" ];
    volume = map md [ "f057f" "f0580" "f057e" ]; # md-volume_low/medium/high
    volumeMuted = md "f0581"; # md-volume_off
    wifi = map md [ "f091f" "f0922" "f0925" "f0928" ]; # md-wifi_strength_1-4
    wifiOff = md "f092e"; # md-wifi_strength_off_outline: on, not connected
    wifiDisabled = md "f05aa"; # md-wifi_off: radio turned off
    bluetooth = md "f00af"; # md-bluetooth
    bluetoothConnected = md "f00b1"; # md-bluetooth_connect
    bluetoothOff = md "f00b2"; # md-bluetooth_off
    # md-battery_10 ... md-battery_90, md-battery (full)
    battery = map md [ "f007a" "f007b" "f007c" "f007d" "f007e" "f007f" "f0080" "f0081" "f0082" "f0079" ];
    # md-battery_charging_10 ... md-battery_charging_100
    batteryCharging = map md [ "f089c" "f0086" "f0087" "f0088" "f089d" "f0089" "f089e" "f008a" "f008b" "f0085" ];
    batteryAlert = md "f0083"; # md-battery_alert
    plug = md "f06a5"; # md-power_plug: on the charger, not charging
  };
  # An icon in polybar's icon font (font 3), in the given color
  barIcon = color: glyph: "%{F${color}}%{T3}${glyph}%{T-}%{F-}";
}
