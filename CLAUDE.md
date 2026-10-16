# CLAUDE.md

Declarative user environment for Aram's Arch Linux laptop, managed with a
Home Manager flake. Everything the user runs (desktop, shells, CLI tools,
theme) is defined here.

## Layout

- `flake.nix`: inputs (nixpkgs `nixos-unstable`, home-manager, which follows
  nixpkgs) and `hosts`, one entry per machine named `user@hostname` with its
  `system` and host file; each becomes a `homeConfigurations` entry.
  `aram@arch-aram` (x86_64-linux, `hosts/dell-7786.nix`) is this laptop,
  also reachable as plain `aram`. A new machine: add a `hosts/<name>.nix`
  and an entry.
- `flake.lock`: pinned inputs. Update only on request (`nix flake update`).
- `hosts/<host>.nix`: one machine. User and home directory,
  `home.stateVersion`, platform bits (`targets.genericLinux` on non-NixOS),
  and which parts are on via the `dotfiles.*` options.
- `modules/`: the configuration, imported by every host
  (`modules/default.nix`):
  - `core/`: always on and machine-independent: shells (`shell.nix`),
    `tmux.nix`, `vim.nix`, `git.nix`, CLI tools.
  - `desktop/` (`dotfiles.desktop.enable`): the X11 desktop. `xsession.nix`
    (bspwm, keyboard layouts, screen lock), `keys.nix` (sxhkd), `bar.nix`
    (polybar, layout flags font), `theme.nix`, `apps.nix` (rofi, Alacritty,
    Firefox), `network.nix` (Wi-Fi/Bluetooth menus, bar modules,
    `bluetooth-setup`), `visualizers.nix` (cava, MilkDrop), `login.nix`
    (`dotfiles.lightdm.enable`: `lightdm-setup`). Option
    `dotfiles.wallpaper`.
  - `laptop/` (`dotfiles.laptop.enable`, plus `battery`, `adapter`,
    `backlight`, `display` names): `battery.nix` (bar), `screen.nix`
    (brightness keys/flash, rotation), `dell-charge-limits.nix`
    (`dotfiles.laptop.dellChargeLimits`: `battery-setup`, `battery-full`).
  Feature modules add their own keys, bar modules and bspwm rules to the
  shared options (`services.sxhkd.keybindings`,
  `services.polybar.settings`, ...).
- `lib/default.nix`: shared values: `nord` palette, polybar `icons`,
  `barIcon`, `char`. Import with
  `inherit (import ../../lib { inherit lib; }) nord icons;`.
- `KEYBINDINGS.md`: user-facing cheat sheet of every key binding.
- `HOST-PACKAGES.md`: what must come from pacman (not Nix) and its
  one-time root setup. Update it when a change needs a host package.
- `.gitignore`: `*.bak`, `result`, `result-*`.

`~/.config/home-manager` is a symlink to this repo (`~/dotfiles`), so
`home-manager` with no `--flake` flag also builds from here.

## Machine facts

- Arch Linux, **not NixOS**: `targets.genericLinux.enable = true`. Nix
  programs use the host GPU drivers via `targets.genericLinux.gpu`.
- X11 session started by LightDM (slick-greeter, Nord), whose `bspwm`
  session runs the `~/.xinitrc` Home Manager writes. LightDM's files live
  outside `$HOME`: after changing `modules/desktop/login.nix`, the user
  reruns `sudo lightdm-setup`.
- Dell Inspiron 7786. Battery charge limits (`dellChargeLimits` in
  `hosts/dell-7786.nix`, Dell
  allows start 50–95, end 55–100; set to 75–80 since it is mostly plugged
  in) are applied by `sudo battery-setup`; `sudo battery-full` sets 95–100
  until the next boot. Both are also shell aliases that run them with sudo
  (sudo doesn't search the Nix profile). The firmware drains the battery on
  the charger when above the stop limit, can then stick at ~50 mA "Charging"
  until the charger is re-plugged, and reads ~8–10 points above Linux's
  percentage; the polybar battery script shows `draining` / `replug`.
- Window manager bspwm, keys by sxhkd, bar polybar, launcher rofi,
  terminal Alacritty, browser Firefox.
- Login shell is still `/usr/bin/bash`. zsh is installed and configured,
  but switching the login shell needs sudo (`/etc/shells` + `chsh`), which
  only the user can do.
- Not available on the host: `python3`, `which`, `ssh`. Use bash/sed, or
  `nix run nixpkgs#<pkg>` for one-off tools.
- No sudo for Claude. Anything needing root: give the user the exact
  command to run with `! <command>`.

## Applying changes

```sh
home-manager build  --flake ~/dotfiles#aram   # build only, catches errors
home-manager switch --flake ~/dotfiles#aram   # build and activate
rm -f result                                  # build leaves this link
```

- Always `build` (or `switch`) after editing a `.nix` file and fix every
  **warning**, not just errors. Option renames and deprecations show up as
  warnings (e.g. `programs.rofi.font` → `programs.rofi.settings.font`).
- If `switch` reports "Existing file ... is in the way", check what the
  file holds and migrate anything worth keeping into the config first, then
  use `home-manager switch -b backup ...` so the old file is kept as
  `*.backup`. Never delete the user's files to get past this.
- **Flakes only see files tracked by git.** A new file must be `git add`ed
  before `build`/`switch` will find it.
- Verify the result for real: start a fresh shell
  (`bash -ic '...'`, `zsh -ic '...'`, or `script -qec '...' /dev/null`
  when a TTY is needed), inspect generated files under `~/.config`, or start
  a throwaway tmux server (`tmux -L test ...`, then `kill-server`).
- `switch` reloads sxhkd by itself when its bindings change (an `onChange`
  hook on `sxhkdrc`); no manual `pkill -USR1 -x sxhkd` needed.
- The X display is `:0`; settings such as `setxkbmap` can be applied live
  with `DISPLAY=:0`.

- For a pure refactor (moving code, no behaviour change), compare the build
  with the previous one: every leaf store path (scripts, config files,
  packages) must stay the same; `comm` the sorted `nix-store -qR` of the
  old and new `activationPackage`. Only collector outputs
  (`home-manager-path`, `-files`, `-generation`, `hm-putter.json`,
  `hm_hmfontconfigfonts.xml`) may differ, through ordering.

## Conventions in the Nix files

- **Machine-specific facts go in `hosts/`**, through `dotfiles.*` options
  (hardware names, charge limits, which parts are on), never hard-coded in
  `modules/`. `core/` must work on any platform; X11 things go in
  `desktop/`, laptop hardware in `laptop/`.
- A module under `desktop/` or `laptop/` wraps its config in
  `lib.mkIf config.dotfiles.<part>.enable`; scripts it needs stay in its
  `let` block, next to the options that use them.
- **Nord everywhere.** Colors come from `nord` in `lib/default.nix`; reuse
  it (and extend it with Nord palette values) instead of hard-coding hex
  values. Theme pieces: GTK `Nordic` (`pkgs.nordic`),
  icons `Papirus-Dark` (`pkgs.papirus-nord`), cursor `Nordic-cursors`,
  Qt via Kvantum `Nordic`, Alacritty `theme = "nord"`, tmux
  `tmuxPlugins.nord`, vim `nord-vim`, fzf colors from `nord`, rofi theme
  built from `nord`.
- Prefer a `programs.<name>` / `services.<name>` module over adding to
  `home.packages`, so config and shell integration are managed too.
- Put a new feature in its own module file (or the closest existing one),
  starting with a short comment on what it is, and keep comments short,
  explaining *why* or what a key does.
- Shell config is shared between bash and zsh: aliases in
  `home.shellAliases`, shared functions as strings in the `let` block of
  `modules/core/shell.nix` (see `fffCd`, used by both
  `programs.bash.initExtra` and `programs.zsh.initContent`).
- Both shells use the starship prompt with the **Pure preset**, read from
  `${pkgs.starship}/share/starship/presets/pure-preset.toml`.
- Check an option exists before using it, e.g.
  `nix eval --impure --expr '(builtins.getFlake (toString ./.)).homeConfigurations.aram.options.programs.foo ? bar'`.
  Check a package with
  `nix eval --raw .#homeConfigurations.aram.pkgs.<name>.name`.
- `home.stateVersion = "25.11"`: never change it.

## Key bindings

When adding or changing any key binding, keybinding-related option, or an
app with keys worth knowing, **update `KEYBINDINGS.md` in the same
commit**, marking user-set bindings **(custom)**.

Current custom bindings, in short:
- sxhkd: `Super` + `Enter` terminal, `Space` rofi, `B` Firefox, `N` Wi-Fi
  menu (networkmanager_dmenu, also a click on Wi-Fi in polybar), `Shift+N`
  Bluetooth menu (rofi-bluetooth, also a click on its icon), `V` cava
  or MilkDrop (style menu, then floating; `Shift` tiled), `H/J/K/L`
  focus (`Shift` swaps), `1-0` desktops (`Shift` sends window), `W` close,
  `M` monocle, `T/S/F` tiled/floating/fullscreen, `Alt+R` restart,
  `Alt+Q` quit; `Print` / `Shift+Print` screenshot of the screen / an area
  to the clipboard (maim + xclip); volume keys via `wpctl` (5% steps,
  capped at 100%);
  brightness keys and scroll on polybar's brightness via `brightnessctl`
  (through logind, since the sysfs file is root-only; down to 0%), via
  `brightnessStep`, which flashes the bar's icon yellow (up) / red (down)
  over polybar IPC.
- Keyboard: layouts `us,am,ru` (am `phonetic-alt`, ru `phonetic`) cycled with `Alt+Shift`,
  shown in polybar as flags (xkeyboard module, `flagFont` built from Noto
  Color Emoji, since polybar can't shape emoji flags);
  `Caps Lock` is `Esc` (`caps:escape`, set via `setxkbmap` in bspwm
  `startupPrograms`).
- tmux: prefix `Ctrl+Space`; `\` and `-` split in the current directory;
  `escapeTime = 0` so `Esc` has no delay in vim.
- Shell: `f` runs fff and `cd`s into the directory it was quit in;
  `z`/`zi` from zoxide; fzf `Ctrl+R`/`Ctrl+T`/`Alt+C`.

## Git workflow

- Remote: `https://github.com/bekverdyan/dotfiles` (HTTPS). Auth goes
  through `gh` (`programs.gh.gitCredentialHelper`); the user has run
  `gh auth login`. Never put tokens in commands, files, or the remote URL.
- `master` is the main branch. Do work on a feature branch, push it, and
  open a PR with `gh pr create` into `master`; the user reviews and merges.
- Commit after each verified change, one logical change per commit, with a
  clear subject and a short body listing what changed.
- Show `git status` and the diff before committing; never commit `*.bak`,
  `result` links, or anything with secrets.
- Before pushing or opening a PR, confirm with the user unless they already
  asked for it.
- `home-manager switch` builds from whatever branch is checked out. If the
  working tree is on a branch without `flake.nix` (e.g. an old commit),
  switch back before building.
- Git identity (`Aram Bekverdyan <aram.bekverdyan@gmail.com>`) is set
  globally by `programs.git`. Older commits in the repo history use
  `bekverdyan@pm.me`.

## Leftovers on the machine

- `~/.config/home-manager.old/`: the original local repo before moving to
  `~/dotfiles`; safe to delete once the user agrees.
- `~/.bashrc.backup`, `~/.bash_profile.backup`: pre-Home-Manager bash files;
  their contents were migrated into `modules/core/shell.nix`.
