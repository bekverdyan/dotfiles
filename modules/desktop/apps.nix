# Desktop apps: rofi (launcher, also the menus' look), Alacritty, Firefox,
# the volume mixer.
{ config, lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [
      pkgs.pavucontrol # volume mixer (right-click the volume in the bar)
    ];
    xsession.windowManager.bspwm.rules."Pavucontrol".state = "floating";

    # Rofi (app launcher, super + space)
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

    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };
  };
}
