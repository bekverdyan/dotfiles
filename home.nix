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
    yellow = "#ebcb8b";
  };

  # Shared by bash and zsh: `f` runs fff, then cds into the dir it was quit in
  fffCd = ''
    f() {
      fff "$@"
      local d="''${XDG_CACHE_HOME:-$HOME/.cache}/fff/.fff_d"
      [[ -f $d ]] && cd "$(< "$d")"
    }
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
    nerd-fonts.jetbrains-mono
    feh # wallpaper
    pavucontrol # volume mixer (click the volume in the bar)
    fff # minimal file manager (`f` cds into the dir you quit in)
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

  # ---------- Firefox ----------
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  # ---------- Shells (bash and zsh) ----------
  home.shellAliases = {
    ls = "ls --color=auto";
    grep = "grep --color=auto";
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
      };
      startupPrograms = [
        # US and Armenian keyboard layouts, switch with Alt+Shift; Caps Lock acts as Esc
        "${pkgs.setxkbmap}/bin/setxkbmap -layout us,am -option grp:alt_shift_toggle,caps:escape"
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
      "super + Return" = "alacritty -e tmux"; # new tmux session per terminal
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
