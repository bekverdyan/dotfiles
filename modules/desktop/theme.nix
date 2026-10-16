# Nord theme for GTK, Qt, icons and cursor, and the font. Firefox and most
# apps follow the GTK theme.
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    fonts.fontconfig.enable = true;

    home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

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
  };
}
