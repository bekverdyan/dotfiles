# Audio visualizers on Super+V (floating) / Super+Shift+V (tiled): a rofi
# menu of cava styles and MilkDrop (projectM). Plain `cava` in a terminal
# uses the default style (the bars preset).
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;

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
      (lib.generators.toINI { } (lib.recursiveUpdate cavaSettings p.set));
  }) cavaPresets);

  # MilkDrop, Winamp's visualizer, through projectM: the projectM team's
  # curated preset pack (~9,800 presets) and the textures many of them use
  milkdropPresets = pkgs.fetchFromGitHub {
    owner = "projectM-visualizer";
    repo = "presets-cream-of-the-crop";
    rev = "0180df21f5e0bd39b9060cc5de420ed2f1f9e509";
    hash = "sha256-4ZyrXmiLR8hyzad9qPjOiDaVEEpPDR+nBr2uTrbRxLw=";
  };
  milkdropTextures = pkgs.fetchFromGitHub {
    owner = "projectM-visualizer";
    repo = "presets-milkdrop-texture-pack";
    rev = "6368812f27bc747b517218fbf89d21d59afce4d9";
    hash = "sha256-wanqBRiJd/I1niuryj5WjQjSmRymZNs8r4TMBsym3BM=";
  };
  # projectMSDL's settings: its packaged defaults (a new preset every 30 s,
  # shuffled, 3 s blends, preset name in the title) with the packs above.
  # Without this file it never changes presets.
  milkdropSettings = pkgs.runCommand "projectMSDL.properties" { } ''
    sed -e 's|^projectM.presetPath = .*|projectM.presetPath = ${milkdropPresets}|' \
        -e 's|^projectM.texturePath = .*|projectM.texturePath = ${milkdropTextures}/textures|' \
        ${pkgs.projectm-sdl-cpp}/share/projectMSDL/projectMSDL.properties > $out
  '';
  # `milkdrop`: projectM on whatever is playing. SDL hides "monitor" sources
  # and would record a microphone instead (which also drops Bluetooth
  # headphones into low-quality headset mode), so show monitors and pick
  # the default output's one by name. pactl comes from the libpulse host
  # package.
  milkdrop = pkgs.writeShellScriptBin "milkdrop" ''
    sink=$(pactl get-default-sink)
    desc=$(pactl list sinks | awk -v s="$sink" '
      $1 == "Name:" { n = $2 }
      $1 == "Description:" && n == s { sub(/^[ \t]*Description: /, ""); print; exit }')
    [ -n "$desc" ] || { echo "milkdrop: no default audio output" >&2; exit 1; }
    SDL_AUDIO_DRIVER=pulseaudio SDL_AUDIO_INCLUDE_MONITORS=1 \
      exec ${pkgs.projectm-sdl-cpp}/bin/projectMSDL -d "Monitor of $desc" "$@"
  '';

  # Super+V / Super+Shift+V: pick a preset (or MilkDrop) in rofi, then open
  # it floating or tiled. $1 is the window class for cava: cava (floating,
  # by a bspwm rule) or cava-tiled. projectMSDL can't set its class, so it
  # gets a one-shot floating rule instead.
  cavaMenu = pkgs.writeShellScript "cava-menu" ''
    choice=$(printf '%s\n' ${lib.escapeShellArgs (map (p: "${p.name}: ${p.about}")
      (builtins.filter (p: builtins.elem p.name cavaMenuPresets) cavaPresets))} \
      'milkdrop: Winamp MilkDrop visuals (projectM)' \
      | rofi -dmenu -i -p cava) || exit 0
    if [ "''${choice%%:*}" = milkdrop ]; then
      [ "$1" = cava-tiled ] ||
        ${config.xsession.windowManager.bspwm.package}/bin/bspc rule -a projectMSDL -o \
          state=floating center=on rectangle=1200x675+0+0
      exec ${milkdrop}/bin/milkdrop
    fi
    preset=${cavaPresetDir}/''${choice%%:*}
    [ -f "$preset" ] || exit 1
    exec alacritty --class "''${1:-cava}" -e cava -p "$preset"
  '';
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [
      milkdrop # MilkDrop visualizer (projectM) on what is playing; also in Super+V
    ];

    programs.cava = {
      enable = true;
      settings = cavaSettings;
    };
    # For reference; the menu reads the presets from the store
    xdg.configFile."cava/presets".source = cavaPresetDir;

    xdg.configFile."projectM/projectMSDL.properties".source = milkdropSettings;

    # Audio visualizer: pick a style, then open it floating / tiled
    services.sxhkd.keybindings."super + {_,shift + }v" = "${cavaMenu} {cava,cava-tiled}";

    # cava window from super + v: floating, centered
    xsession.windowManager.bspwm.rules."cava" = {
      state = "floating";
      rectangle = "1200x420+0+0";
      center = true;
    };
  };
}
