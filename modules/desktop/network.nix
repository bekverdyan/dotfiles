# Wi-Fi and Bluetooth: rofi menus, their keys, their polybar modules, and
# the BlueZ settings. The daemons come from the host (NetworkManager, bluez).
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord icons barIcon;
  # The Nix clients, so the scripts don't depend on the host's PATH; they
  # talk to the host's NetworkManager and bluetoothd over D-Bus
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";

  # Polybar Wi-Fi label: signal icon and network name when connected, a red
  # icon when Wi-Fi is on but not connected, a dimmed one when it is off.
  # A script, since internal/network can't tell those last two apart.
  # --rescan no reads the last scan instead of starting a new one every few
  # seconds.
  wifiStatus = pkgs.writeShellScript "polybar-wifi" ''
    if [ "$(${nmcli} radio wifi)" != enabled ]; then
      echo "${barIcon nord.muted icons.wifiDisabled} %{F${nord.muted}}off%{F-}"; exit
    fi
    line=$(${nmcli} -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no | grep -m1 '^\*:')
    if [ -z "$line" ]; then
      echo "${barIcon nord.red icons.wifiOff} %{F${nord.red}}offline%{F-}"; exit
    fi
    line=''${line#\*:}; signal=''${line%%:*}; ssid=''${line#*:}; ssid=''${ssid//\\:/:}
    strength=(${lib.escapeShellArgs icons.wifi})
    i=$(( signal / 25 )); (( i > 3 )) && i=3
    echo "${barIcon nord.accent "\${strength[i]}"} $ssid"
  '';

  # Polybar Bluetooth label: a dimmed crossed-out icon when off, the icon
  # alone when on, and the connected devices' names after a pink connected
  # icon, each with its battery level if it reports one (yellow at 20% or
  # less). Battery levels need BlueZ's Experimental option (bluetooth-setup).
  bluetoothStatus = pkgs.writeShellScript "polybar-bluetooth" ''
    if ! ${bluetoothctl} show 2>/dev/null | grep -q 'Powered: yes'; then
      echo "${barIcon nord.muted icons.bluetoothOff}"; exit
    fi
    out=
    while read -r _ mac name; do
      # "Battery Percentage: 0x50 (80)" -> 80
      bat=$(${bluetoothctl} info "$mac" | sed -n 's/.*Battery Percentage: .*(\([0-9]*\)).*/\1/p')
      if [ -n "$bat" ] && (( bat <= 20 )); then bat="%{F${nord.yellow}}$bat%%{F-}"
      elif [ -n "$bat" ]; then bat="$bat%"; fi
      out+="''${out:+, }''${name:0:20}''${bat:+ $bat}"
    done < <(${bluetoothctl} devices Connected)
    if [ -n "$out" ]; then echo "${barIcon nord.pink icons.bluetoothConnected} $out"
    else echo "${barIcon nord.accent icons.bluetooth}"; fi
  '';

  # BlueZ settings in /etc/bluetooth/main.conf (needs root, so applied by
  # `sudo bluetooth-setup`). Experimental enables the battery level of
  # headphones and the like; AutoEnable powers the adapter at boot.
  bluetoothConf = pkgs.writeText "bluetooth-main.conf" ''
    [General]
    Experimental = true

    [Policy]
    AutoEnable = true
  '';
  bluetoothSetup = pkgs.writeShellScriptBin "bluetooth-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    conf=/etc/bluetooth/main.conf
    # Keep the packaged file once, for reference
    [ -e $conf.orig ] || cp $conf $conf.orig
    install -m644 ${bluetoothConf} $conf
    systemctl restart bluetooth
    echo "Bluetooth configured (original kept as $conf.orig)"
  '';
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [
      pkgs.networkmanager_dmenu # Wi-Fi menu in rofi (Super+N, or click Wi-Fi in the bar)
      pkgs.rofi-bluetooth # Bluetooth menu in rofi (Super+Shift+N, or click BT in the bar)
      bluetoothSetup # `sudo bluetooth-setup` writes /etc/bluetooth/main.conf
    ];

    # Full store path: sudo doesn't search the Nix profile
    home.shellAliases.bluetooth-setup = "sudo ${bluetoothSetup}/bin/bluetooth-setup";

    services.sxhkd.keybindings = {
      "super + n" = "networkmanager_dmenu"; # Wi-Fi menu
      "super + shift + n" = "rofi-bluetooth"; # Bluetooth menu
    };

    # networkmanager_dmenu: pick, connect to and manage networks in rofi.
    # `%%` is a literal `%` (Python ConfigParser).
    xdg.configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = rofi -dmenu -i -theme-str 'window {width: 30%%;}'
      highlight = True
      compact = True
      prompt = Wi-Fi

      [dmenu_passphrase]
      # Hides the password as you type (rofi -password)
      obscure = True
      show_pass = alacritty --hold -e ${nmcli} device wifi show-password

      [editor]
      # "Launch Connection Manager" opens nmtui in Alacritty
      terminal = alacritty
      gui_if_available = False

      [nmdm]
      # No notification daemon is running
      show_notifications = False
    '';

    services.polybar.settings = {
      "module/wifi" = {
        type = "custom/script";
        exec = wifiStatus;
        interval = 5;
        click.left = "networkmanager_dmenu &";
      };

      "module/bluetooth" = {
        type = "custom/script";
        exec = bluetoothStatus;
        interval = 5;
        click.left = "rofi-bluetooth &";
      };
    };
  };
}
