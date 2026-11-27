# Android apps through Waydroid, launched like desktop apps (from rofi).
# Waydroid needs Wayland, so on X11 it draws into a nested Weston window,
# phone-sized and floating; closing that window stops Android. Waydroid
# itself is a host package (HOST-PACKAGES.md).
{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.waydroid;
  real = "/usr/bin/waydroid";
  socket = "wayland-waydroid";
  bspc = "${pkgs.bspwm}/bin/bspc";
  xdotool = "${pkgs.xdotool}/bin/xdotool";

  # Shadows /usr/bin/waydroid on PATH. Waydroid's own .desktop entries
  # (~/.local/share/applications/waydroid.*) run `waydroid app launch <pkg>`,
  # which needs the display and a session: start both first, wait for
  # Android to boot, then show the window. `app install` also needs a
  # running Android. Everything else passes through.
  wrapper = pkgs.writeShellScriptBin "waydroid" ''
    case "$1 $2" in
      " "|"first-launch "*|"show-full-ui "*|"app launch"|"app intent"|"app install") ;;
      *) exec ${real} "$@" ;;
    esac
    [ $# -eq 0 ] || [ "$1" = first-launch ] && set -- show-full-ui

    fresh=
    if ! systemctl --user -q is-active waydroid-session; then
      systemctl --user start waydroid-session || exit 1
      fresh=1
    fi
    for _ in $(seq 120); do
      [ "$(${real} prop get sys.boot_completed 2>/dev/null)" = 1 ] && break
      sleep 1
    done
    # The window shows nothing until the full UI has been up once
    [ -n "$fresh" ] && [ "$1" != show-full-ui ] && ${real} show-full-ui

    ${real} "$@" || exit
    # An install from a terminal keeps the focus there
    [ "$1 $2" = "app install" ] && exit 0
    win=$(${xdotool} search --class 'Weston Compositor' | head -1)
    [ -n "$win" ] && ${bspc} node "$win" -f
  '';

  # Docker sets the FORWARD policy to DROP, which beats Waydroid's own
  # nftables accept, so Android gets no internet. DOCKER-USER is Docker's
  # chain for exceptions; add waydroid0 there whenever the container starts.
  allowForward = dir: "ExecStartPost=-/bin/sh -c 'iptables -C DOCKER-USER ${dir} waydroid0 -j ACCEPT 2>/dev/null"
    + " || iptables -I DOCKER-USER ${dir} waydroid0 -j ACCEPT'";
  dockerForward = pkgs.writeText "waydroid-docker-forward.conf" ''
    [Unit]
    After=docker.service
    [Service]
    ${allowForward "-i"}
    ${allowForward "-o"}
  '';
  waydroidSetup = pkgs.writeShellScriptBin "waydroid-setup" ''
    set -eu
    [ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
    install -Dm644 ${dockerForward} /etc/systemd/system/waydroid-container.service.d/docker-forward.conf
    systemctl daemon-reload
    for dir in -i -o; do
      iptables -C DOCKER-USER $dir waydroid0 -j ACCEPT 2>/dev/null ||
        iptables -I DOCKER-USER $dir waydroid0 -j ACCEPT || true
    done
  '';
in
{
  options.dotfiles.waydroid = {
    enable = lib.mkEnableOption "Android apps through Waydroid (host package), from rofi";
    width = lib.mkOption {
      type = lib.types.int;
      default = 540;
      description = "Width of the Android window.";
    };
    height = lib.mkOption {
      type = lib.types.int;
      default = 960;
      description = "Height of the Android window.";
    };
  };

  config = lib.mkIf (config.dotfiles.desktop.enable && cfg.enable) {
    home.packages = [ wrapper waydroidSetup ];
    # sudo doesn't search the Nix profile
    home.shellAliases.waydroid-setup = "sudo ${waydroidSetup}/bin/waydroid-setup";

    # Weston's X11 window, one Android screen (kiosk: each app fills it)
    systemd.user.services.waydroid-weston = {
      Unit = {
        Description = "Weston window for Waydroid";
        PartOf = [ "waydroid-session.service" ];
      };
      Service.ExecStart = "${pkgs.weston}/bin/weston --backend=x11 --shell=kiosk"
        + " --socket=${socket} --width=${toString cfg.width} --height=${toString cfg.height}";
    };

    # The Android session, drawing into that window; ends with the window
    systemd.user.services.waydroid-session = {
      Unit = {
        Description = "Waydroid Android session";
        BindsTo = [ "waydroid-weston.service" ];
        After = [ "waydroid-weston.service" ];
      };
      Service = {
        Environment = "WAYLAND_DISPLAY=${socket}";
        # Weston creates the socket a moment after it starts
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'for _ in $(seq 50); do [ -S \"$XDG_RUNTIME_DIR/${socket}\" ] && exit 0; sleep 0.1; done; exit 1'";
        ExecStart = "${real} session start";
        ExecStop = "${real} session stop";
      };
    };

    xsession.windowManager.bspwm.rules."Weston Compositor".state = "floating";
  };
}
