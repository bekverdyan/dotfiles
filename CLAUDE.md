# CLAUDE.md

Declarative user environment for Aram's Arch Linux laptop, managed with a
Home Manager flake. Everything the user runs (desktop, shells, CLI tools,
theme) is defined here.

## Layout

- `flake.nix`: inputs (nixpkgs `nixos-unstable`, home-manager, which follows
  nixpkgs) and the single output `homeConfigurations."aram"` (x86_64-linux).
- `flake.lock`: pinned inputs. Update only on request (`nix flake update`).
- `home.nix`: the whole configuration, in one file, split by
  `# ---------- Section ----------` comments.
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
  outside `$HOME`: after changing them in `home.nix`, the user reruns
  `sudo lightdm-setup`.
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

- Always `build` (or `switch`) after editing `home.nix` and fix every
  **warning**, not just errors. Option renames and deprecations show up as
  warnings (e.g. `programs.rofi.font` → `programs.rofi.settings.font`).
- If `switch` reports "Existing file ... is in the way", check what the
  file holds and migrate anything worth keeping into `home.nix` first, then
  use `home-manager switch -b backup ...` so the old file is kept as
  `*.backup`. Never delete the user's files to get past this.
- **Flakes only see files tracked by git.** A new file must be `git add`ed
  before `build`/`switch` will find it.
- Verify the result for real: start a fresh shell
  (`bash -ic '...'`, `zsh -ic '...'`, or `script -qec '...' /dev/null`
  when a TTY is needed), inspect generated files under `~/.config`, or start
  a throwaway tmux server (`tmux -L test ...`, then `kill-server`).
- The X display is `:0`; settings such as `setxkbmap` can be applied live
  with `DISPLAY=:0`.

## Conventions in `home.nix`

- **Nord everywhere.** Colors come from the `nord` attrset in the `let`
  block; reuse it (and extend it with Nord palette values) instead of
  hard-coding hex values. Theme pieces: GTK `Nordic` (`pkgs.nordic`),
  icons `Papirus-Dark` (`pkgs.papirus-nord`), cursor `Nordic-cursors`,
  Qt via Kvantum `Nordic`, Alacritty `theme = "nord"`, tmux
  `tmuxPlugins.nord`, vim `nord-vim`, fzf colors from `nord`, rofi theme
  built from `nord`.
- Prefer a `programs.<name>` / `services.<name>` module over adding to
  `home.packages`, so config and shell integration are managed too.
- Put a new section under a `# ---------- Name ----------` header, and keep
  comments short, explaining *why* or what a key does.
- Shell config is shared between bash and zsh: aliases in
  `home.shellAliases`, shared functions as strings in the `let` block (see
  `fffCd`, used by both `programs.bash.initExtra` and
  `programs.zsh.initContent`).
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
  menu (networkmanager_dmenu, also a click on Wi-Fi in polybar), `H/J/K/L`
  focus (`Shift` swaps), `1-0` desktops (`Shift` sends window), `W` close,
  `M` monocle, `T/S/F` tiled/floating/fullscreen, `Alt+R` restart,
  `Alt+Q` quit; volume keys via `wpctl` (5% steps, capped at 100%);
  brightness keys and scroll on polybar's `BRI` via `brightnessctl`
  (through logind, since the sysfs file is root-only; floor 5%).
- Keyboard: layouts `us,am` toggled with `Alt+Shift`; `Caps Lock` is `Esc`
  (`caps:escape`, set via `setxkbmap` in bspwm `startupPrograms`).
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
  their contents were migrated into `home.nix`.
