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
    feh # wallpaper
    pavucontrol # volume mixer (click the volume in the bar)
    fff # minimal file manager (`f` cds into the dir you quit in)
    blurlock # lock the screen (also Super+Alt+L)
    networkmanager_dmenu # Wi-Fi menu in rofi (Super+N, or click Wi-Fi in the bar)
    lightdmSetup # `sudo lightdm-setup` installs the login screen
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
      "XF86MonBrightness{Up,Down}" = "${setBrightness} 5%{+,-}";
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
        modules.right = "backlight pulseaudio wifi battery date";
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

      # Polybar's own scrolling writes to the root-only sysfs file, so
      # scroll actions run brightnessctl instead (A4 up, A5 down)
      "module/backlight" = {
        type = "internal/backlight";
        card = "intel_backlight";
        use-actual-brightness = true;
        enable-scroll = false;
        format = "%{A4:${setBrightness} 5%+:}%{A5:${setBrightness} 5%-:}<label>%{A}%{A}";
        label = "BRI %percentage%%";
      };

      "module/wifi" = {
        type = "internal/network";
        interface.type = "wireless";
        label.connected = "%essid%";
        label.disconnected = {
          text = "offline";
          foreground = nord.muted;
        };
        # Wrap the label in a click action that opens the Wi-Fi menu
        format.connected = "%{A1:networkmanager_dmenu &:}<label-connected>%{A}";
        format.disconnected = "%{A1:networkmanager_dmenu &:}<label-disconnected>%{A}";
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
  # The service's PATH is only polybar itself; add the Home Manager profile
  # and the host so click actions (pavucontrol, Wi-Fi menu) can run
  systemd.user.services.polybar.Service.Environment = pkgs.lib.mkForce
    "PATH=${config.services.polybar.package}/bin:${config.home.profileDirectory}/bin:/usr/bin";
}
