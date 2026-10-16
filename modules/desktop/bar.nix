# Status bar (polybar): the bar, and the modules that need nothing special
# (desktops, window title, volume, keyboard layout, date). Wi-Fi and
# Bluetooth are in network.nix, battery and brightness in ../laptop/.
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord char icons;
  laptop = config.dotfiles.laptop.enable;

  # Keyboard layout flags for polybar. Polybar can't shape emoji flags (a
  # pair of regional-indicator letters), so this font maps each Noto Color
  # Emoji flag to one private-use code point that polybar draws as a glyph.
  # BMP code points: fontconfig ignores the plane-16 private-use area.
  # The layouts themselves are set in xsession.nix (setxkbmap).
  layoutFlags = { us = "US"; am = "AM"; ru = "RU"; }; # xkb layout -> country
  flagCodes = lib.imap0 (i: layout: {
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
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [ flagFont ]; # keyboard layout flags in polybar

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
          # Brightness and battery only on laptops
          modules.right = lib.concatStringsSep " " (
            [ "xkeyboard" ]
            ++ lib.optional laptop "backlight"
            ++ [ "pulseaudio" "wifi" "bluetooth" ]
            ++ lib.optional laptop "battery"
            ++ [ "date" ]
          );
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
    systemd.user.services.polybar.Service.Environment = lib.mkForce
      "PATH=${config.services.polybar.package}/bin:${config.home.profileDirectory}/bin:/usr/bin";
  };
}
