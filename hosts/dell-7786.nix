# Aram's Dell Inspiron 7786, running Arch Linux (not NixOS)
{
  imports = [ ../modules ];

  home.username = "aram";
  home.homeDirectory = "/home/aram";
  home.stateVersion = "25.11"; # set once, never change it

  # Arch (non-NixOS) integration. This also turns on targets.genericLinux.gpu,
  # which lets Nix programs such as Alacritty use the GPU drivers. It needs a
  # one-time `sudo .../non-nixos-gpu-setup`; `home-manager switch` prints the
  # exact command when it's needed.
  targets.genericLinux.enable = true;

  dotfiles = {
    desktop.enable = true;
    # LightDM's files live outside $HOME here: `sudo lightdm-setup`
    lightdm.enable = true;
    # Desktop 9 goes to an external monitor while one is plugged in
    externalMonitor.desktops = [ "9" ];
    # Android emulators together: half the 8 CPU threads, at most 4 GB of
    # the 16 GB RAM (slowed and swapped above 3.5 GB)
    emulatorLimits = {
      enable = true;
      cpuQuota = "400%";
      memoryHigh = "3584M";
      memoryMax = "4G";
    };

    laptop = {
      enable = true;
      battery = "BAT0";
      adapter = "AC";
      backlight = "intel_backlight";
      display = "eDP-1";
      # 75-80 suits a laptop that is mostly plugged in
      dellChargeLimits = {
        enable = true;
        start = 75;
        end = 80;
      };
    };
  };
}
