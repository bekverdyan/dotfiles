# Shells: bash and zsh share the aliases (home.shellAliases) and the `f`
# function, and both use the starship prompt. Plus fzf, zoxide, ranger and
# less.
{ lib, pkgs, ... }:
let
  inherit (import ../../lib { inherit lib; }) nord;

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
}
