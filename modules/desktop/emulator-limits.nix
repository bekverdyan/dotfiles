# CPU and memory limits for Android emulators, all of them together, so a
# running emulator leaves the rest of the desktop responsive. Projects start
# the emulator from their own Nix SDKs (e.g. ~/code/player/emulator.sh), so
# instead of wrapping one binary, a watcher moves any process run from an
# SDK's emulator/ directory into emulator.slice, which holds the limits.
{ config, lib, pkgs, ... }:
let
  cfg = config.dotfiles.emulatorLimits;
  busctl = "${pkgs.systemd}/bin/busctl";

  # Every few seconds: each emulator process (emulator, qemu-system-*,
  # netsimd, ...) not yet in the slice gets its own scope in it. systemd
  # adopts running processes this way (as GNOME does for launched apps);
  # their later children stay in the scope.
  watcher = pkgs.writeShellScript "emulator-limits" ''
    while :; do
      for p in /proc/[0-9]*; do
        exe=$(readlink "$p/exe" 2>/dev/null) || continue
        case $exe in */emulator/*) ;; *) continue ;; esac
        grep -q '/emulator\.slice/' "$p/cgroup" 2>/dev/null && continue
        pid=''${p#/proc/}
        ${busctl} --user call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
          org.freedesktop.systemd1.Manager StartTransientUnit 'ssa(sv)a(sa(sv))' \
          "emulator-$pid.scope" fail 3 \
          PIDs au 1 "$pid" Slice s emulator.slice \
          Description s "Android emulator ''${exe##*/}" \
          0 >/dev/null || echo "couldn't move $pid ($exe)" >&2
      done
      sleep 3
    done
  '';
in
{
  options.dotfiles.emulatorLimits = {
    enable = lib.mkEnableOption "CPU and memory limits for Android emulators";
    cpuQuota = lib.mkOption {
      type = lib.types.str;
      default = "400%";
      description = "CPU time all emulators may use together; 100% is one CPU thread.";
    };
    memoryHigh = lib.mkOption {
      type = lib.types.str;
      default = "6G";
      description = "Memory above which the emulators are slowed and pushed to swap.";
    };
    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "8G";
      description = "Hard memory limit; past it the kernel kills an emulator.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.slices.emulator = {
      Unit.Description = "Android emulators, CPU and memory limited";
      Slice = {
        CPUQuota = cfg.cpuQuota;
        # Below the default 100: the desktop wins when both want the CPU
        CPUWeight = 50;
        MemoryHigh = cfg.memoryHigh;
        MemoryMax = cfg.memoryMax;
      };
    };

    systemd.user.services.emulator-limits = {
      Unit.Description = "Move Android emulators into emulator.slice";
      Service = {
        ExecStart = "${watcher}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
