| `Super+Ctrl+H/J/K/L` | Grow window left / down / up / right (20 px) |
| `Super+Ctrl+Shift+H/J/K/L` | Shrink window from the right / top / bottom / left (20 px) |
| `Super` + right-drag / middle-drag | Resize from the nearest corner / side (bspwm default) |
| `Super` + left-drag | Move a floating window (bspwm default) |
# Key bindings

Cheat sheet for everything installed by this configuration (`modules/`).
Bindings marked **(custom)** are set in `modules/`; the rest are the app's defaults.

`Super` is the Windows/Logo key. `Prefix` (tmux) is `Ctrl+Space`.

## Keyboard (system-wide)

| Keys | Action |
|---|---|
| `Alt+Shift` | Switch layout: US → Armenian (alt. phonetic: `8` is Ր, `R` is Ռ) → Russian (phonetic) → US; polybar shows its flag 🇺🇸 / 🇦🇲 / 🇷🇺 **(custom)** |
| `Caps Lock` | Acts as `Esc` **(custom)** |

## bspwm + sxhkd (window manager)

All **(custom)**.

| Keys | Action |
|---|---|
| `Super+Enter` | Open terminal (Alacritty) running a new tmux session |
| `Super+Space` | App launcher (rofi) |
| `Super+B` | Open Firefox |
| `Super+N` | Wi-Fi menu (networkmanager_dmenu) |
| `Super+Shift+N` | Bluetooth menu (rofi-bluetooth) |
| `Super+V` | Audio visualizer: pick a cava style or MilkDrop, opens floating |
| `Super+Shift+V` | Audio visualizer: pick a cava style or MilkDrop, opens tiled |
| `Super+H/J/K/L` | Focus window left / down / up / right |
| `Super+Shift+H/J/K/L` | Swap window left / down / up / right |
| `Super+1` … `Super+0` | Go to desktop 1 … 10 |
| `Super+Shift+1` … `Super+Shift+0` | Send window to desktop 1 … 10 |
| `Super+W` | Close window |
| `Super+Shift+W` | Kill window (force) |
| `Super+M` | Toggle monocle (one window fills the desktop) |
| `Super+T` | Tiled |
| `Super+Shift+T` | Pseudo-tiled |
| `Super+S` | Floating |
| `Super+F` | Fullscreen |
| `Super+Ctrl+↑` | Screen rotation: normal |
| `Super+Ctrl+←` / `Super+Ctrl+→` | Rotate screen left / right (portrait) |
| `Super+Ctrl+↓` | Rotate screen upside down |
| `Volume Up` / `Volume Down` | Volume up / down by 5% (max 100%) |
| `Mute` | Mute / unmute |
| `Brightness Up` / `Brightness Down` | Screen brightness up / down by 5% (down to 0%, backlight off); the bar's sun flashes yellow / red |
| `Print` | Screenshot of the whole screen, copied to the clipboard (paste with `Ctrl+V`) |
| `Shift+Print` | Screenshot of an area (drag) or a window (click), copied to the clipboard; `Esc` cancels |
| `Super+Esc` | Reload key bindings |
| `Super+Alt+L` | Lock the screen (blurlock) |
| `Super+Alt+R` | Restart bspwm |
| `Super+Alt+Q` | Quit bspwm (log out) |

## Polybar (status bar)

| Action | Result |
|---|---|
| Right-click volume | Open volume mixer (pavucontrol) **(custom)** |
| Left-click volume | Mute / unmute |
| Scroll on volume | Volume up / down |
| Left-click Wi-Fi name | Open the Wi-Fi menu **(custom)** |
| Left-click Bluetooth (󰂯) | Open the Bluetooth menu **(custom)** |
| Scroll on brightness (󰖨) | Screen brightness up / down by 5%, sun flashes yellow / red **(custom)** |

## Wi-Fi menu (networkmanager_dmenu, `Super+N`)

Runs in rofi, so rofi's keys apply: type to filter, `Enter` to pick, `Esc`
to close. The active network is highlighted.

Also opens with a click on Wi-Fi in polybar: the signal icon and network
name when connected, a red 󰤮 `offline` when Wi-Fi is on but not connected,
and a dimmed 󰖪 `off` when Wi-Fi is turned off.

| Entry | Action |
|---|---|
| A network name | Connect (asks for the password the first time) |
| Disable / Enable WiFi | Turn the Wi-Fi radio off / on |
| Disable / Enable Networking | Turn all networking off / on |
| Disable / Enable Bluetooth | Turn Bluetooth off / on |
| Rescan WiFi Networks | Search again for networks |
| Delete a Connection | Forget a saved network |
| Show WiFi password | Show the current network's password and QR code |
| Launch Connection Manager | Open `nmtui` in Alacritty (edit connections, VPNs) **(custom)** |

## Bluetooth menu (rofi-bluetooth, `Super+Shift+N`)

Also opens with a click on the Bluetooth icon in polybar: dimmed 󰂲 when off,
󰂯 when on, and a pink 󰂱 with the device names when connected, each with its
battery level if the device reports one (yellow at 20% or less).
Pick a device in the menu to open its submenu.

| Entry | Action |
|---|---|
| A device name | Open its submenu: Connect/Disconnect, Pair, Trust |
| Power: on / off | Turn the Bluetooth adapter on / off |
| Scan: on / off | Search for new devices (about 5 seconds) |
| Pairable / Discoverable | Let other devices pair with / find the laptop |

To add a device: put it in pairing mode, turn **Scan** on, pick it, then
**Pair** and **Trust**. Trusted devices reconnect on their own when they are
turned on nearby.

## cava (audio visualizer, `Super+V` floating, `Super+Shift+V` tiled)

Shows whatever is playing, in a Nord gradient.

| Keys | Action |
|---|---|
| `Up` / `Down` | Sensitivity up / down (taller / shorter bars) |
| `Left` / `Right` | Bars wider / narrower |
| `f` / `b` | Cycle foreground / background color |
| `r` / `c` | Reload the config / only the colors |
| `q` | Quit |

Both keys first open a rofi menu of styles (`Esc` cancels): `aurora` (Nord
Aurora colors, red to purple), `retro` (a few wide bars), `calm` (slow,
floating movement), `bass` (only the low end, 30–350 Hz), `dense` (thin
bars, no gaps), and `milkdrop`
(Winamp's MilkDrop visuals, see the next section).

More styles are defined in `modules/desktop/visualizers.nix` (`cavaPresets`) but hidden from the
menu: `bars` (the default for plain `cava`), `spectrum`, `center`, `hanging`,
`hills`, `waves`, `center-hills`, `blocks`, `labels`. Add a name to
`cavaMenuPresets` to show it again.

## MilkDrop (projectM, `milkdrop` in the `Super+V` menu)

Winamp's MilkDrop visualizer through projectM, with the projectM team's
"Cream of the Crop" pack (~9,800 presets). It shows what is playing on the
current output (headphones or speakers); a new preset blends in every 30
seconds, in random order, and the window title shows its name. Also runs as
the `milkdrop` command.

| Keys | Action |
|---|---|
| `n` / `p` | Next / previous preset |
| `r` | Random preset |
| `Backspace` | Back to the last shown preset |
| `Space` | Lock the current preset (stop changing) / unlock |
| `y` | Shuffle on / off |
| `Up` / `Down` | Beat sensitivity up / down |
| Scroll up / down | Next / previous preset |
| `Ctrl+F` | Fullscreen on / off |
| `Ctrl+Q` | Quit |
| `Esc` | Settings panel |

## rofi (app launcher)

| Keys | Action |
|---|---|
| Type | Filter apps |
| `↑` `↓` / `Ctrl+P` `Ctrl+N` | Move selection |
| `Enter` | Launch |
| `Esc` | Close |

## Alacritty (terminal)

| Keys | Action |
|---|---|
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy / paste |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | Bigger / smaller / reset font |
| `Ctrl+Shift+Space` | Vi mode (move and select with the keyboard) |
| `Ctrl+Shift+F` | Search scrollback |

## tmux

`Prefix` = `Ctrl+Space` **(custom)**: press it, release, then press the key.
Mouse is on **(custom)**: click panes, drag borders, scroll.

| Keys | Action |
|---|---|
| `Prefix \` | Split side by side, in the current folder **(custom)** |
| `Prefix -` | Split top / bottom, in the current folder **(custom)** |
| `Prefix ←↑→↓` | Move between panes |
| `Prefix Z` | Zoom pane in / out |
| `Prefix X` | Close pane |
| `Prefix C` | New window |
| `Prefix N` / `Prefix P` | Next / previous window |
| `Prefix 0` … `Prefix 9` | Go to window 0 … 9 |
| `Prefix ,` | Rename window |
| `Prefix &` | Close window |
| `Prefix S` | Pick a session |
| `Prefix D` | Detach (`tmux attach` to return) |
| `Prefix [` | Scroll / copy mode (`q` to leave) |
| `Prefix ?` | List all bindings |

## Shell (bash and zsh)

### fzf

| Keys | Action |
|---|---|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Pick a file, insert its path |
| `Alt+C` | Pick a folder, `cd` into it |
| `**` then `Tab` | Fuzzy-complete, e.g. `vim **<Tab>` |

### Commands

| Command | Action |
|---|---|
| `z <part of name>` | Jump to a frequently used folder (zoxide) |
| `zi` | Pick a folder from a fuzzy list (zoxide + fzf) |
| `f` | fff, then stay in the folder you quit in **(custom)** |
| `fff` | fff, return to where you started |
| `ranger` | ranger file manager |

### zsh only

| Keys | Action |
|---|---|
| `→` / `End` / `Ctrl+E` | Accept the grey suggestion |
| `Alt+F` | Accept the next word of the suggestion |
| Type a folder name + `Enter` | `cd` into it (autocd) |

## fff (file manager)

| Keys | Action |
|---|---|
| `h` `j` `k` `l` / arrows | Parent / down / up / open |
| `Enter` | Open |
| `g` / `G` | Top / bottom |
| `/` | Search |
| `.` | Show / hide hidden files |
| `~` / `t` / `-` | Go home / to trash / to previous folder |
| `:` | Go to a typed path |
| `1` … `9` | Go to a favourite folder (`FFF_FAV1` … `FFF_FAV9`) |
| `y` / `m` / `s` / `d` | Mark to copy / move / symlink / trash |
| `Y` / `M` / `S` / `D` | Mark **all** to copy / move / symlink / trash |
| `p` | Do it here (paste) |
| `c` | Clear marks |
| `r` / `b` | Rename / bulk rename |
| `n` / `f` | New folder / new file |
| `x` / `X` | Show file attributes / toggle executable |
| `i` | Show image |
| `!` | Open a shell here |
| `e` | Refresh |
| `q` | Quit (with `f`: your shell stays in this folder) |

## ranger (file manager)

| Keys | Action |
|---|---|
| `h` `j` `k` `l` | Parent / down / up / open |
| `gg` / `G` | Top / bottom |
| `gh` | Go home |
| `/` then `n` / `N` | Search, next / previous match |
| `zh` | Show / hide hidden files |
| `Space` / `v` / `uv` | Mark / mark all / unmark all |
| `yy` / `dd` / `pp` | Copy / cut / paste |
| `dD` | Delete |
| `cw` | Rename |
| `E` | Edit in vim |
| `r` | Open with… |
| `i` | Preview file |
| `S` | Open a shell here (`exit` to return) |
| `gn` / `gt` / `gT` | New tab / next tab / previous tab |
| `w` | Running tasks |
| `q` | Quit (your shell stays where it was) |

## vim

Nord colors only; keys are vim's defaults. `Caps Lock` works as `Esc`, with no delay inside tmux **(custom)**.

| Keys | Action |
|---|---|
| `i` / `Esc` | Insert mode / back to normal mode |
| `:w` / `:q` / `:wq` / `:q!` | Save / quit / save and quit / quit without saving |

## less (pager for git, gh, man)

| Keys | Action |
|---|---|
| `Space` / `b` | Page down / up |
| `j` / `k` | Line down / up |
| `/` then `n` / `N` | Search, next / previous match |
| `g` / `G` | Top / bottom |
| `q` | Quit |

## htop

| Keys | Action |
|---|---|
| `F3` or `/` | Search process |
| `F4` or `\` | Filter |
| `F5` or `t` | Tree view |
| `F6` | Sort by column |
| `F9` or `k` | Kill process |
| `F10` or `q` | Quit |

## gtop

System monitor dashboard (CPU, memory, network, disk, processes). Keys are gtop's defaults.

| Keys | Action |
|---|---|
| `c` | Sort processes by CPU |
| `m` | Sort processes by memory |
| `p` | Sort processes by PID |
| Same key again | Reverse the sort order |
| `q`, `Esc` or `Ctrl+C` | Quit |

## gotop

System monitor (CPU, memory, temperatures, network, disk, processes), in Nord colors **(custom)**. Keys are gotop's defaults; `?` shows them all.

| Keys | Action |
|---|---|
| `j` / `k` | Move down / up the process list |
| `gg` / `G` | Jump to top / bottom |
| `c` / `m` / `p` / `n` | Sort processes by CPU / memory / PID / command |
| `/` | Filter processes (`Enter` keeps it, `Esc` clears it) |
| `Tab` | Group processes by name |
| `dd` | Kill the selected process (SIGTERM) |
| `d9` | Kill the selected process (SIGKILL) |
| `h` / `l` | Zoom the CPU and memory graphs in / out |
| `q` or `Ctrl+C` | Quit |
