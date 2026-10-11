{ config, pkgs, ... }:

let
  # To use your own picture, put it in ~/Pictures and change this line to:
  #   wallpaper = "${config.home.homeDirectory}/Pictures/wallpaper.jpg";
  wallpaper = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

  # Nord colors, shared by bspwm borders and polybar
  nord = {
    bg = "#2e3440";
    bgAlt = "#3b4252";
    fg = "#d8dee9";
    muted = "#4c566a";
    accent = "#88c0d0";
    red = "#bf616a";
    yellow = "#ebcb8b";
  };
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
    nerd-fonts.jetbrains-mono
    rofi # app launcher (super + space)
    feh # wallpaper
    pavucontrol # volume mixer (click the volume in the bar)
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    TERMINAL = "alacritty";
    BROWSER = "firefox";
  };

  # ---------- Firefox ----------
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
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
      };
      startupPrograms = [
        # US and Armenian keyboard layouts, switch with Alt+Shift
        "${pkgs.setxkbmap}/bin/setxkbmap -layout us,am -option grp:alt_shift_toggle"
        "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ${wallpaper}"
        # Restart the bar once bspwm runs, so the desktop list connects
        "systemctl --user restart polybar"
      ];
    };
  };

  # ---------- Keybindings ----------
  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + Return" = "alacritty";
      "super + space" = "rofi -show drun";
      "super + b" = "firefox";
      "super + Escape" = "pkill -USR1 -x sxhkd"; # reload keybindings
      "super + alt + {q,r}" = "bspc {quit,wm -r}"; # quit / restart bspwm
      "super + {_,shift + }w" = "bspc node -{c,k}"; # close / kill window
      "super + m" = "bspc desktop -l next"; # toggle fullscreen-like monocle
      "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseudo_tiled,floating,fullscreen}";
      "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";
      "super + {_,shift + }{1-9,0}" = "bspc {desktop -f,node -d} '^{1-9,10}'";
    };
  };

  # ---------- Status bar ----------
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override { pulseSupport = true; };
    script = "polybar main &";
    settings = {
      "bar/main" = {
        width = "100%";
        height = 28;
        background = nord.bg;
        foreground = nord.fg;
        font = [ "JetBrainsMono Nerd Font:size=10;2" ];
        padding = 1;
        module.margin = 1;
        separator = {
          text = "|";
          foreground = nord.muted;
        };
        modules.left = "bspwm";
        modules.center = "title";
        modules.right = "pulseaudio wifi battery date";
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
        format.volume = "<label-volume>";
        label.volume = "VOL %percentage%%";
        label.muted = {
          text = "muted";
          foreground = nord.muted;
        };
        click.right = "pavucontrol";
      };

      "module/wifi" = {
        type = "internal/network";
        interface.type = "wireless";
        label.connected = "%essid%";
        label.disconnected = {
          text = "offline";
          foreground = nord.muted;
        };
      };

      # Check the names with: ls /sys/class/power_supply
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "AC";
        full.at = 99;
        label.charging = "CHG %percentage%%";
        label.discharging = "BAT %percentage%%";
        label.full = "FULL";
        label.low = {
          text = "LOW %percentage%%";
          foreground = nord.yellow;
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
}
