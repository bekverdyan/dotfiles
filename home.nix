{ config, pkgs, ... }:

let
  # To use your own picture, put it in ~/Pictures and change this line to:
  #   wallpaper = "${config.home.homeDirectory}/Pictures/wallpaper.jpg";
  wallpaper = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

  # Nord colors, shared by bspwm borders, polybar and rofi
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
      hex4 = n: pkgs.lib.fixedWidthString 4 "0" (pkgs.lib.toHexString n);
      c = code - 65536;
    in builtins.fromJSON (if code < 65536 then ''"\u${hex4 code}"''
      else ''"\u${hex4 (55296 + c / 1024)}\u${hex4 (56320 + pkgs.lib.mod c 1024)}"'');

  # Polybar icons: Material Design glyphs of the JetBrainsMono Nerd Font, by
  # code point (look names up at nerdfonts.com/cheat-sheet)
  md = hex: char (pkgs.lib.fromHexString hex);
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

  # cava settings: the default style (programs.cava) and the base of every
  # preset in the super + v menu
  cavaSettings = {
    general = {
      framerate = 60;
      bar_width = 2;
      bar_spacing = 1;
    };
    # PipeWire's default output monitor: whatever is playing
    input = {
      method = "pipewire";
      source = "auto";
    };
    output.synchronized_sync = 1; # no flicker in Alacritty
    # Bottom to top: Nord frost blues fading into Nord pink. Hex colors
    # must be quoted; the background stays the terminal's Nord one.
    color = {
      gradient = 1;
      gradient_color_1 = "'${nord.frost4}'";
      gradient_color_2 = "'${nord.frost3}'";
      gradient_color_3 = "'${nord.accent}'";
      gradient_color_4 = "'${nord.frost1}'";
      gradient_color_5 = "'${nord.pink}'";
    };
  };
  # Visualizer styles: each is cavaSettings with these changes
  cavaPresets = [
    { name = "bars"; about = "mirrored bars, bass in the middle (default)"; set = { }; }
    { name = "spectrum"; about = "bass on the left, treble on the right"; set.output.channels = "mono"; }
    { name = "center"; about = "bars up and down from a center line"; set.output.orientation = "horizontal"; }
    { name = "hanging"; about = "bars hanging from the top"; set.output.orientation = "top"; }
    { name = "hills"; about = "smooth peaks (Monstercat)"; set.smoothing.monstercat = 1; }
    { name = "waves"; about = "rolling waves"; set.smoothing = { monstercat = 1; waves = 1; }; }
    {
      name = "center-hills";
      about = "smooth spectrum mirrored around a center line";
      set = {
        output = { orientation = "horizontal"; channels = "mono"; };
        smoothing.monstercat = 1;
      };
    }
    {
      name = "dense";
      about = "thin bars, no gaps";
      set = {
        general = { bar_width = 1; bar_spacing = 0; };
        output.channels = "mono";
      };
    }
    { name = "blocks"; about = "wide chunky bars"; set.general = { bar_width = 4; bar_spacing = 1; }; }
    {
      name = "labels";
      about = "spectrum with frequency labels";
      set.output = { channels = "mono"; xaxis = "frequency"; };
    }
    {
      name = "aurora";
      about = "Nord Aurora colors: red to purple";
      set.color = {
        gradient_color_1 = "'${nord.red}'";
        gradient_color_2 = "'${nord.orange}'";
        gradient_color_3 = "'${nord.yellow}'";
        gradient_color_4 = "'${nord.green}'";
        gradient_color_5 = "'${nord.pink}'";
      };
    }
    {
      name = "retro";
      about = "a few wide bars, like an old hi-fi equalizer";
      # Wide bars; a fixed count would fail in narrow windows
      set.general = { bar_width = 6; bar_spacing = 2; };
    }
    { name = "calm"; about = "slow, floating movement"; set.smoothing.noise_reduction = 95; }
    {
      # cava needs about 43 Hz of range per bar, so few bars keep it bass-only
      name = "bass";
      about = "only the low end (30-350 Hz): kick drums and bass";
      set = {
        general = {
          bars = 8;
          bar_width = 6; # 8 bars x (6 + 2) = 64 columns, fits a half-screen tile
          bar_spacing = 2;
          lower_cutoff_freq = 30;
          higher_cutoff_freq = 350;
        };
        output.channels = "mono";
      };
    }
  ];
  # Presets offered in the super + v menu; the others stay defined (and in
  # ~/.config/cava/presets) but hidden. Add a name back to show it again.
  cavaMenuPresets = [ "aurora" "retro" "calm" "bass" ];
  cavaPresetDir = pkgs.linkFarm "cava-presets" (map (p: {
    inherit (p) name;
    path = pkgs.writeText "cava-${p.name}"
      (pkgs.lib.generators.toINI { } (pkgs.lib.recursiveUpdate cavaSettings p.set));
  }) cavaPresets);
  # Super+V / Super+Shift+V: pick a preset in rofi, then open it in a window
  # of the class given as $1: cava (floating, by a bspwm rule) or cava-tiled
  cavaMenu = pkgs.writeShellScript "cava-menu" ''
    choice=$(printf '%s\n' ${pkgs.lib.escapeShellArgs (map (p: "${p.name}: ${p.about}")
      (builtins.filter (p: builtins.elem p.name cavaMenuPresets) cavaPresets))} \
      | rofi -dmenu -i -p cava) || exit 0
    preset=${cavaPresetDir}/''${choice%%:*}
    [ -f "$preset" ] || exit 1
    exec alacritty --class "''${1:-cava}" -e cava -p "$preset"
  '';

  # Keyboard layout flags for polybar. Polybar can't shape emoji flags (a
  # pair of regional-indicator letters), so this font maps each Noto Color
  # Emoji flag to one private-use code point that polybar draws as a glyph.
  # BMP code points: fontconfig ignores the plane-16 private-use area.
  layoutFlags = { us = "US"; am = "AM"; ru = "RU"; }; # xkb layout -> country
  flagCodes = pkgs.lib.imap0 (i: layout: {
    inherit layout;
    country = layoutFlags.${layout};
    code = 57344 + i; # U+E000, U+E001, ...
  }) (builtins.attrNames layoutFlags);
  flagFont = pkgs.runCommand "polybar-flags-font" {
    nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.fonttools ])) ];
    flags = builtins.toJSON (map (f: [ f.code f.country ]) flagCodes);
    passAsFile = [ "script" ];
    script = ''
      import json, os, sys
      from fontTools.ttLib import TTFont
      from fontTools import subset
      f = TTFont(sys.argv[1])
      cmap = f.getBestCmap()
      ri = lambda c: cmap[0x1F1E6 + ord(c) - ord("A")]
      # A flag is the GSUB ligature of its two regional indicators
      ligs = {}
      for lookup in f["GSUB"].table.LookupList.Lookup:
          for st in lookup.SubTable:
              st = getattr(st, "ExtSubTable", st)
              for first, ls in getattr(st, "ligatures", {}).items():
                  for l in ls:
                      if len(l.Component) == 1:
                          ligs[(first, l.Component[0])] = l.LigGlyph
      pua = {code: ligs[(ri(cc[0]), ri(cc[1]))] for code, cc in json.loads(os.environ["flags"])}
      for t in f["cmap"].tables:
          if t.isUnicode():
              t.cmap.update(pua)
      opts = subset.Options()
      opts.layout_features = []
      opts.name_IDs = ["*"]
      s = subset.Subsetter(opts)
      s.populate(unicodes=list(pua))
      s.subset(f)
      for rec in f["name"].names:
          if rec.nameID in (1, 4, 16):
              rec.string = "Polybar Flags"
          if rec.nameID == 6:
              rec.string = "PolybarFlags"
      f.save(sys.argv[2])
    '';
  } ''
    mkdir -p $out/share/fonts/truetype
    python3 $scriptPath ${pkgs.noto-fonts-color-emoji}/share/fonts/noto/NotoColorEmoji.ttf \
      $out/share/fonts/truetype/PolybarFlags.ttf
  '';

  # Shared by bash and zsh: `f` runs fff, then cds into the dir it was quit in
  fffCd = ''
    f() {
      fff "$@"
      local d="''${XDG_CACHE_HOME:-$HOME/.cache}/fff/.fff_d"
      [[ -f $d ]] && cd "$(< "$d")"
    }
  '';

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

  # Set the screen brightness: `${setBrightness} 5%+`. The sysfs file is
  # root-only, so brightnessctl goes through logind. -n0 lets it reach 0%
  # (backlight off; brightness up brings it back).
  setBrightness = "${pkgs.brightnessctl}/bin/brightnessctl -q -d intel_backlight -n0 set";

  # Polybar brightness label: a sun (outline below 50%, filled from 50%) in
  # the given color, and the percentage
  brightnessLabel = color: pkgs.writeShellScript "polybar-brightness" ''
    pct=$(${pkgs.brightnessctl}/bin/brightnessctl -d intel_backlight -m | cut -d, -f4)
    pct=''${pct%\%}
    sun=(${pkgs.lib.escapeShellArgs icons.brightness})
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

  # LightDM login screen (slick-greeter) in Nord. The greeter runs as the
  # `lightdm` user and can't see the Nix profile, so `sudo lightdm-setup`
  # copies the theme, cursor, font, wallpaper and config into the system.
  # Rerun it after changing anything here.
  slickGreeterConf = pkgs.writeText "slick-greeter.conf" ''
    [Greeter]
    background=/usr/local/share/backgrounds/login-wallpaper
    background-color=${nord.bg}
    draw-user-backgrounds=false
    draw-grid=false
    theme-name=Nordic
    icon-theme-name=Papirus-Dark
    cursor-theme-name=Nordic-cursors
    cursor-theme-size=24
    font-name=JetBrainsMono Nerd Font 11
    clock-format=%a %d %b  %H:%M
  '';
  lightdmConf = pkgs.writeText "50-home-manager.conf" ''
    [Seat:*]
    greeter-session=lightdm-slick-greeter
    user-session=bspwm
  '';
  # Starts the same ~/.xinitrc that `startx` used
  bspwmSession = pkgs.writeText "bspwm.desktop" ''
    [Desktop Entry]
    Name=bspwm
    Comment=bspwm session from Home Manager
    Exec=${config.home.homeDirectory}/.xinitrc
    Type=Application
  '';
  lightdmSetup = pkgs.writeShellScriptBin "lightdm-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    share=/usr/local/share
    font=${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono
    rm -rf $share/themes/Nordic $share/icons/Nordic-cursors
    install -d $share/themes $share/icons $share/fonts/JetBrainsMono
    cp -rL --no-preserve=mode,ownership ${pkgs.nordic}/share/themes/Nordic $share/themes/
    cp -rL --no-preserve=mode,ownership ${pkgs.nordic}/share/icons/Nordic-cursors $share/icons/
    install -m644 $font/JetBrainsMonoNerdFont-{Regular,Bold}.ttf $share/fonts/JetBrainsMono/
    fc-cache -f $share/fonts
    install -Dm644 ${wallpaper} $share/backgrounds/login-wallpaper
    install -Dm644 ${slickGreeterConf} /etc/lightdm/slick-greeter.conf
    install -Dm644 ${lightdmConf} /etc/lightdm/lightdm.conf.d/50-home-manager.conf
    install -Dm644 ${bspwmSession} /usr/share/xsessions/bspwm.desktop
    echo "LightDM is set up. Enable it with: sudo systemctl enable lightdm"
  '';

  # Battery charge limits, kept by the Dell firmware (dell_laptop driver):
  # charging stops at `end` and starts again below `start`. Dell allows
  # start 50-95 and end 55-100, at least 5 apart. Writing needs root, so
  # `sudo battery-setup` applies them and installs a tmpfiles rule that
  # reapplies them at boot. Rerun it after changing them. 75-80 suits a
  # laptop that is mostly plugged in; `sudo battery-full` sets 95-100 to
  # charge to full until the next boot (or `sudo battery-setup`).
  battery = { start = 75; end = 80; };
  # The stop must stay at least 5 above the start, so the order of writes
  # matters. At boot, start goes first: that lowers a leftover battery-full
  # 95-100 before the stop comes down. Then Custom mode, so the firmware
  # uses the thresholds
  batteryTmpfiles = pkgs.writeText "battery-charge.conf" ''
    w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - ${toString battery.start}
    w /sys/class/power_supply/BAT0/charge_control_end_threshold - - - - ${toString battery.end}
    w /sys/class/power_supply/BAT0/charge_types - - - - Custom
  '';
  batterySetup = pkgs.writeShellScriptBin "battery-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    install -Dm644 ${batteryTmpfiles} /etc/tmpfiles.d/battery-charge.conf
    cd /sys/class/power_supply/BAT0
    # Start at the minimum first, so any new pair can be written after it
    echo 50 > charge_control_start_threshold
    echo ${toString battery.end} > charge_control_end_threshold
    echo ${toString battery.start} > charge_control_start_threshold
    echo Custom > charge_types
    echo "Charge from $(cat charge_control_start_threshold)% to $(cat charge_control_end_threshold)%, mode: $(cat charge_types)"
  '';
  # Polybar battery label: a level icon on battery, a green charging icon
  # while charging, a plug when plugged in but not charging (held by the
  # limits, or full), and a yellow alert at 10% or less. Above the stop
  # limit on the charger (after battery-full), a yellow plug says "unplug":
  # the firmware can't discharge, only using the battery brings it down.
  # The limit is read from the firmware, so battery-full's 100 shows no hint.
  # Check the names with: ls /sys/class/power_supply
  batteryStatus = pkgs.writeShellScript "polybar-battery" ''
    bat=/sys/class/power_supply/BAT0
    read -r status < $bat/status
    read -r pct < $bat/capacity
    read -r stop < $bat/charge_control_end_threshold
    level=(${pkgs.lib.escapeShellArgs icons.battery})
    charging=(${pkgs.lib.escapeShellArgs icons.batteryCharging})
    i=$(( (pct + 5) / 10 )); (( i < 1 )) && i=1; (( i > 10 )) && i=10
    case $status in
      Charging) echo "${barIcon nord.green "\${charging[i-1]}"} $pct%" ;;
      Discharging)
        if (( pct <= 10 )); then echo "${barIcon nord.yellow icons.batteryAlert} %{F${nord.yellow}}$pct%%{F-}"
        else echo "${barIcon nord.accent "\${level[i-1]}"} $pct%"; fi ;;
      *) # "Not charging", "Full"
        if (( pct > stop )); then echo "${barIcon nord.yellow icons.plug} %{F${nord.yellow}}$pct% unplug%{F-}"
        else echo "${barIcon nord.accent icons.plug} $pct%"; fi ;;
    esac
  '';
  # Polybar Bluetooth label: a dimmed crossed-out icon when off, the icon
  # alone when on, and the connected devices' names after a pink connected
  # icon, each with its battery level if it reports one (yellow at 20% or
  # less). Battery levels need BlueZ's Experimental option (bluetooth-setup).
  # bluetoothctl comes from the bluez host package.
  bluetoothStatus = pkgs.writeShellScript "polybar-bluetooth" ''
    if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
      echo "${barIcon nord.muted icons.bluetoothOff}"; exit
    fi
    out=
    while read -r _ mac name; do
      # "Battery Percentage: 0x50 (80)" -> 80
      bat=$(bluetoothctl info "$mac" | sed -n 's/.*Battery Percentage: .*(\([0-9]*\)).*/\1/p')
      if [ -n "$bat" ] && (( bat <= 20 )); then bat="%{F${nord.yellow}}$bat%%{F-}"
      elif [ -n "$bat" ]; then bat="$bat%"; fi
      out+="''${out:+, }''${name:0:20}''${bat:+ $bat}"
    done < <(bluetoothctl devices Connected)
    if [ -n "$out" ]; then echo "${barIcon nord.pink icons.bluetoothConnected} $out"
    else echo "${barIcon nord.accent icons.bluetooth}"; fi
  '';

  # Polybar Wi-Fi label: signal icon and network name when connected, a red
  # icon when Wi-Fi is on but not connected, a dimmed one when it is off.
  # A script, since internal/network can't tell those last two apart.
  # nmcli comes from the networkmanager host package; --rescan no reads the
  # last scan instead of starting a new one every few seconds.
  wifiStatus = pkgs.writeShellScript "polybar-wifi" ''
    if [ "$(nmcli radio wifi)" != enabled ]; then
      echo "${barIcon nord.muted icons.wifiDisabled} %{F${nord.muted}}off%{F-}"; exit
    fi
    line=$(nmcli -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no | grep -m1 '^\*:')
    if [ -z "$line" ]; then
      echo "${barIcon nord.red icons.wifiOff} %{F${nord.red}}offline%{F-}"; exit
    fi
    line=''${line#\*:}; signal=''${line%%:*}; ssid=''${line#*:}; ssid=''${ssid//\\:/:}
    strength=(${pkgs.lib.escapeShellArgs icons.wifi})
    i=$(( signal / 25 )); (( i > 3 )) && i=3
    echo "${barIcon nord.accent "\${strength[i]}"} $ssid"
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

  # Charging only begins below the start, so lift both (the highest Dell
  # allows) to charge now, even from 76-80%
  batteryFull = pkgs.writeShellScriptBin "battery-full" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    cd /sys/class/power_supply/BAT0
    echo 100 > charge_control_end_threshold
    echo 95 > charge_control_start_threshold
    echo "Charging to 100% until reboot; battery-setup restores ${toString battery.start}-${toString battery.end}%"
  '';
in
{
  home.username = "aram";
  home.homeDirectory = "/home/aram";
  home.stateVersion = "25.11"; # set once, never change it

  # Arch (non-NixOS) integration. This also turns on targets.genericLinux.gpu,
  # which lets Nix programs such as Alacritty use the GPU drivers. It needs a
  # one-time `sudo .../non-nixos-gpu-setup`; `home-manager switch` prints the
  # exact command when it's needed.
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    htop
    gtop # system monitor dashboard
    gotop # system monitor, Nord colors (see the gotop section)
    nerd-fonts.jetbrains-mono
    flagFont # keyboard layout flags in polybar
    feh # wallpaper
    pavucontrol # volume mixer (click the volume in the bar)
    fff # minimal file manager (`f` cds into the dir you quit in)
    blurlock # lock the screen (also Super+Alt+L)
    networkmanager_dmenu # Wi-Fi menu in rofi (Super+N, or click Wi-Fi in the bar)
    rofi-bluetooth # Bluetooth menu in rofi (Super+Shift+N, or click BT in the bar)
    bluetoothSetup # `sudo bluetooth-setup` writes /etc/bluetooth/main.conf
    lightdmSetup # `sudo lightdm-setup` installs the login screen
    batterySetup # `sudo battery-setup` sets the battery charge limits
    batteryFull # `sudo battery-full` charges to 100% once, e.g. before a trip
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    EDITOR = "vim";
    TERMINAL = "alacritty";
    BROWSER = "firefox";
  };

  # ---------- Nord theme for GTK, Qt, icons and cursor ----------
  # Firefox and most apps follow the GTK theme.
  gtk = {
    enable = true;
    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-nord;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.pointerCursor = {
    enable = true;
    name = "Nordic-cursors";
    package = pkgs.nordic;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
  xdg.configFile = {
    "Kvantum/Nordic".source = "${pkgs.nordic}/share/Kvantum/Nordic";
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Nordic
    '';
  };

  # ---------- Rofi (app launcher, super + space) ----------
  programs.rofi = {
    enable = true;
    settings = {
      terminal = "alacritty";
      font = "JetBrainsMono Nerd Font 11";
      show-icons = true;
      icon-theme = "Papirus-Dark";
    };
    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = {
          background-color = mkLiteral nord.bg;
          text-color = mkLiteral nord.fg;
        };
        window = {
          width = mkLiteral "40%";
          border = mkLiteral "2px";
          border-color = mkLiteral nord.accent;
          padding = mkLiteral "12px";
        };
        inputbar = {
          children = map mkLiteral [ "prompt" "entry" ];
          spacing = mkLiteral "8px";
          padding = mkLiteral "8px";
          background-color = mkLiteral nord.bgAlt;
        };
        "prompt, entry" = {
          background-color = mkLiteral "inherit";
        };
        prompt.text-color = mkLiteral nord.accent;
        listview = {
          lines = 8;
          padding = mkLiteral "8px 0 0";
        };
        element = {
          padding = mkLiteral "6px 8px";
          spacing = mkLiteral "8px";
        };
        "element selected" = {
          background-color = mkLiteral nord.bgHi;
          text-color = mkLiteral nord.accent;
        };
        "element-text, element-icon" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
      };
  };

  # ---------- Vim ----------
  programs.vim = {
    enable = true;
    plugins = [ pkgs.vimPlugins.nord-vim ];
    extraConfig = ''
      syntax on
      colorscheme nord
    '';
  };

  # ---------- gotop (system monitor) ----------
  # Unset keys keep gotop's defaults
  xdg.configFile."gotop/gotop.conf".text = ''
    colorscheme=nord
  '';

  # ---------- cava (audio visualizer, super + v) ----------
  # Super+V / Super+Shift+V: a rofi menu of the presets in the let block,
  # then the chosen style opens floating / tiled. Plain `cava` in a
  # terminal uses the default style (the bars preset).
  programs.cava = {
    enable = true;
    settings = cavaSettings;
  };
  # For reference; the menu reads the presets from the store
  xdg.configFile."cava/presets".source = cavaPresetDir;

  # ---------- Firefox ----------
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  # ---------- Shells (bash and zsh) ----------
  home.shellAliases = {
    ls = "ls --color=auto";
    grep = "grep --color=auto";
    # Full store paths: sudo doesn't search the Nix profile
    battery-setup = "sudo ${batterySetup}/bin/battery-setup";
    battery-full = "sudo ${batteryFull}/bin/battery-full";
    bluetooth-setup = "sudo ${bluetoothSetup}/bin/bluetooth-setup";
  };

  programs.bash = {
    enable = true;
    initExtra = fffCd;
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      ignoreDups = true;
      share = true;
    };
    initContent = fffCd;
  };

  # Prompt for bash and zsh, using starship's "pure" preset
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (
      builtins.readFile "${pkgs.starship}/share/starship/presets/pure-preset.toml"
    );
  };

  # ---------- Tmux ----------
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    prefix = "C-Space";
    escapeTime = 0; # no lag after Esc in vim
    focusEvents = true; # pass focus in/out to apps (vim autoread, Claude Code)
    mouse = true;
    plugins = [ pkgs.tmuxPlugins.nord ];
    extraConfig = ''
      set -as terminal-features ",alacritty:RGB"

      # Split panes with \ and -, in the current directory
      bind '\' split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
    '';
  };

  # Fuzzy finder: Ctrl+T files, Ctrl+R history, Alt+C cd
  programs.fzf = {
    enable = true;
    colors = {
      bg = nord.bg;
      "bg+" = nord.bgAlt;
      fg = nord.fg;
      "fg+" = nord.fg;
      hl = nord.accent;
      "hl+" = nord.accent;
      border = nord.muted;
      info = nord.yellow;
      pointer = nord.accent;
      prompt = nord.accent;
      marker = nord.yellow;
    };
  };

  # `z <part of a dir>` jumps to frequently used dirs, `zi` picks with fzf
  programs.zoxide.enable = true;

  programs.ranger.enable = true;

  # Pager used by git, gh and man
  programs.less.enable = true;

  # ---------- Git / GitHub ----------
  programs.git = {
    enable = true;
    settings.user = {
      name = "Aram Bekverdyan";
      email = "aram.bekverdyan@gmail.com";
    };
  };

  # Run `gh auth login` once; git then gets GitHub credentials from gh
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # ---------- Alacritty ----------
  programs.alacritty = {
    enable = true;
    theme = "nord";
    settings = {
      window.padding = {
        x = 8;
        y = 8;
      };
      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 11;
      };
    };
  };

  # ---------- X session ----------
  # Home Manager writes ~/.xinitrc, so `startx` starts bspwm.
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
      rules = {
        "Pavucontrol".state = "floating";
        # cava window from super + v: floating, centered
        "cava" = {
          state = "floating";
          rectangle = "1200x420+0+0";
          center = true;
        };
      };
      startupPrograms = [
        # US, Armenian (phonetic-alt: 8 is Ր, R is Ռ) and Russian (phonetic)
        # layouts, cycled with Alt+Shift; Caps Lock acts as Esc
        "${pkgs.setxkbmap}/bin/setxkbmap -layout us,am,ru -variant ,phonetic-alt,phonetic -option grp:alt_shift_toggle,caps:escape"
        "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${wallpaper}"
        # Restart the bar once bspwm runs, so the desktop list connects
        "systemctl --user restart polybar"
      ];
    };
  };

  # ---------- Screen lock ----------
  # xss-lock runs blurlock after 10 idle minutes and before suspend.
  # Super+Alt+L locks through logind, so only one locker ever runs.
  services.screen-locker = {
    enable = true;
    lockCmd = "${blurlock}/bin/blurlock";
    inactiveInterval = 10;
    xautolock.enable = false; # the X screensaver timer is enough
  };

  # ---------- Keybindings ----------
  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + Return" = "alacritty -e tmux"; # new tmux session per terminal
      "super + space" = "rofi -show drun";
      "super + b" = "firefox";
      "super + n" = "networkmanager_dmenu"; # Wi-Fi menu
      "super + shift + n" = "rofi-bluetooth"; # Bluetooth menu
      # Audio visualizer: pick a style, then open it floating / tiled
      "super + {_,shift + }v" = "${cavaMenu} {cava,cava-tiled}";
      "super + Escape" = "pkill -USR1 -x sxhkd"; # reload keybindings
      "super + alt + {q,r}" = "bspc {quit,wm -r}"; # quit / restart bspwm
      "super + alt + l" = "loginctl lock-session"; # blurlock
      "super + {_,shift + }w" = "bspc node -{c,k}"; # close / kill window
      "super + m" = "bspc desktop -l next"; # toggle fullscreen-like monocle
      "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseudo_tiled,floating,fullscreen}";
      "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";
      "super + {_,shift + }{1-9,0}" = "bspc {desktop -f,node -d} '^{1-9,10}'";
      # Rotate the laptop screen; restarting bspwm reruns startupPrograms, which
      # redraws the wallpaper and restarts polybar at the new size
      "super + ctrl + {Up,Left,Right,Down}" =
        "${pkgs.xrandr}/bin/xrandr --output eDP-1 --rotate {normal,left,right,inverted} && bspc wm -r";
      # Laptop volume keys; -l 1.0 caps the volume at 100%
      "XF86Audio{Raise,Lower}Volume" =
        "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%{+,-}";
      "XF86AudioMute" = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      # Laptop brightness keys
      "XF86MonBrightness{Up,Down}" = "${brightnessStep} {up,down}";
    };
  };

  # ---------- Wi-Fi menu (super + n, or click Wi-Fi in the bar) ----------
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
    show_pass = alacritty --hold -e nmcli device wifi show-password

    [editor]
    # "Launch Connection Manager" opens nmtui in Alacritty
    terminal = alacritty
    gui_if_available = False

    [nmdm]
    # No notification daemon is running
    show_notifications = False
  '';

  # ---------- Status bar ----------
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override { pulseSupport = true; };
    script = "polybar main &";
    settings = {
      "bar/main" = {
        width = "100%";
        height = 28;
        bottom = true; # at the bottom of the screen
        enable-ipc = true; # polybar-msg, used by brightnessStep
        background = nord.bg;
        foreground = nord.fg;
        font = [
          "JetBrainsMono Nerd Font:size=10;2"
          "Polybar Flags:scale=10;2" # font 2: layout flags
          # font 3: icons, a bit larger than the text; the Propo variant
          # gives icons their full width, so they don't touch the text
          "JetBrainsMono Nerd Font Propo:size=13;3"
        ];
        padding = 1;
        module.margin = 1;
        separator = {
          text = "|";
          foreground = nord.muted;
        };
        modules.left = "bspwm";
        modules.center = "title";
        modules.right = "xkeyboard backlight pulseaudio wifi bluetooth battery date";
        wm-restack = "bspwm";
      };

      "module/bspwm" = {
        type = "internal/bspwm";
        label.focused = {
          text = "%name%";
          background = nord.bgAlt;
          foreground = nord.accent;
          padding = 1;
        };
        label.occupied = {
          text = "%name%";
          padding = 1;
        };
        label.urgent = {
          text = "%name%";
          foreground = nord.red;
          padding = 1;
        };
        label.empty = "";
      };

      "module/title" = {
        type = "internal/xwindow";
        label = "%title:0:60:…%";
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format.volume = "<ramp-volume> <label-volume>";
        label.volume = "%percentage%%";
        ramp.volume = {
          text = icons.volume;
          foreground = nord.accent;
          font = 3;
        };
        label.muted = {
          text = "%{T3}${icons.volumeMuted}%{T-} %percentage%%";
          foreground = nord.muted;
        };
        click.right = "pavucontrol";
      };

      # Active keyboard layout (switch with Alt+Shift)
      "module/xkeyboard" = {
        type = "internal/xkeyboard";
        format = "<label-layout>"; # no Caps/Num Lock indicators
        # A flag per layout, drawn with font 2 (flagFont)
        layout.icon = map (f: "${f.layout};${char f.code}") flagCodes;
        label.layout = {
          text = "%icon%";
          font = 2;
        };
      };

      # custom/ipc, so brightnessStep can flash the icon: hook 0 is the normal
      # label, 1 yellow (brightness up), 2 red (down). It updates only through
      # those hooks, i.e. the brightness keys and scrolling on it.
      "module/backlight" = {
        type = "custom/ipc";
        hook = map (color: "${brightnessLabel color}") [ nord.accent nord.yellow nord.red ];
        initial = 1; # hook 0 at start
        scroll.up = "${brightnessStep} up";
        scroll.down = "${brightnessStep} down";
      };

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

      # A script, since internal/battery shows "Not charging" (plugged in,
      # held by the charge limits) as discharging
      "module/battery" = {
        type = "custom/script";
        exec = batteryStatus;
        interval = 5;
      };

      "module/date" = {
        type = "internal/date";
        interval = 5;
        date = "%a %d %b";
        time = "%H:%M";
        label = "%date%  %time%";
      };
    };
  };
  # The service's PATH is only polybar itself; add the Home Manager profile
  # and the host so click actions (pavucontrol, Wi-Fi menu) can run
  systemd.user.services.polybar.Service.Environment = pkgs.lib.mkForce
    "PATH=${config.services.polybar.package}/bin:${config.home.profileDirectory}/bin:/usr/bin";
}
