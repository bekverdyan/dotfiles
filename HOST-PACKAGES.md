# Host packages

Everything in `home.nix` comes from Nix. This file lists what has to be
installed on Arch itself with `pacman`, and the one-time setup each piece
needs. Mostly these are things that run as root or outside `$HOME`, like
drivers, system services, PAM and the login screen.

Commands that start with `sudo` need root. Follow the steps in order on a
fresh install.

## 1. Base system

Installed with `pacstrap` during the Arch install:

```sh
pacstrap -K /mnt base linux linux-firmware intel-ucode sof-firmware \
  mkinitcpio efibootmgr zram-generator sudo git
```

| Package | Why |
| --- | --- |
| `base`, `linux`, `linux-firmware` | the system and kernel |
| `intel-ucode` | CPU microcode updates (Intel CPU) |
| `sof-firmware` | firmware for the laptop's sound card |
| `mkinitcpio`, `efibootmgr` | initramfs and UEFI boot entry |
| `zram-generator` | compressed swap in RAM |
| `sudo` | root access for the user (in group `wheel`) |
| `git` | clone this repo before Home Manager exists |

## 2. Nix and Home Manager

Home Manager needs Nix. Nix comes from pacman, and it needs a running daemon
and flakes turned on.

```sh
sudo pacman -S nix
sudo systemctl enable --now nix-daemon
sudo usermod -aG nix-users aram          # log out and back in afterwards
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

Activate this repo for the first time (`home-manager` isn't installed yet,
so it runs straight from the flake):

```sh
git clone https://github.com/bekverdyan/dotfiles ~/dotfiles
ln -s ~/dotfiles ~/.config/home-manager
nix run home-manager/master -- switch -b backup --flake ~/dotfiles#aram
```

After the first switch, `home-manager switch` works on its own.

**GPU for Nix programs.** `targets.genericLinux.gpu` needs a one-time setup
command run as root. `home-manager switch` prints it, and it looks like
`sudo /nix/store/...-non-nixos-gpu/bin/non-nixos-gpu-setup`. Run it once,
and again whenever `switch` asks.

## 3. X11 and graphics

```sh
sudo pacman -S xorg-server xorg-xinit mesa xf86-video-nouveau vulkan-nouveau
```

| Package | Why |
| --- | --- |
| `xorg-server` | the X server bspwm runs on |
| `xorg-xinit` | `startx`, a fallback to start `~/.xinitrc` without LightDM |
| `mesa` | OpenGL for the Intel UHD 620 (built-in GPU) |
| `xf86-video-nouveau`, `vulkan-nouveau` | open drivers for the NVIDIA MX150 |

## 4. Login screen (LightDM)

The greeter runs as the `lightdm` user, so it can't see the Nix profile.

```sh
sudo pacman -S lightdm lightdm-slick-greeter papirus-icon-theme
home-manager switch --flake ~/dotfiles#aram    # puts lightdm-setup on PATH
sudo "$(command -v lightdm-setup)"             # copies theme, font, configs
sudo systemctl enable lightdm
```

| Package | Why |
| --- | --- |
| `lightdm` | display manager, starts the `bspwm` session |
| `lightdm-slick-greeter` | the greeter set in `slick-greeter.conf` |
| `papirus-icon-theme` | `Papirus-Dark` icons for the greeter (Nix copy isn't visible to it) |

Rerun `sudo "$(command -v lightdm-setup)"` after changing the LightDM part of
`home.nix`. `sudo` resets `PATH`, which is why the full path is passed.

## 5. Screen lock

```sh
sudo pacman -S i3lock
```

`blurlock` (`Super+Alt+L`, and xss-lock on idle or suspend) calls
`/usr/bin/i3lock`. A Nix-built i3lock can't check passwords on Arch, because
PAM needs the host's setuid helper.

## 6. Sound

```sh
sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack \
  wireplumber gst-plugin-pipewire libpulse
```

| Package | Why |
| --- | --- |
| `pipewire`, `wireplumber` | sound server and its session manager |
| `pipewire-pulse` | PulseAudio API, used by the polybar volume module and pavucontrol |
| `pipewire-alsa`, `pipewire-jack` | route ALSA and JACK apps through PipeWire |
| `gst-plugin-pipewire` | GStreamer apps (browsers, players) through PipeWire |
| `libpulse` | PulseAudio client library and `pactl` (also used by `milkdrop`) |

The user services are socket-activated, so nothing needs enabling. To check:
`systemctl --user status pipewire wireplumber`.

## 7. Network, Bluetooth, power

```sh
sudo pacman -S networkmanager wpa_supplicant bluez bluez-utils power-profiles-daemon
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
```

| Package | Why |
| --- | --- |
| `networkmanager`, `wpa_supplicant` | Wi-Fi (`nmtui` / `nmcli`), shown in polybar |
| `bluez`, `bluez-utils` | Bluetooth stack and `bluetoothctl` |
| `power-profiles-daemon` | power profiles (`powerprofilesctl`) |

Connect to Wi-Fi from a TTY with `nmtui`.

Then write the BlueZ settings (battery level of headphones, adapter on at
boot) to `/etc/bluetooth/main.conf`; the packaged file is kept as
`main.conf.orig`:

```sh
bluetooth-setup   # alias for: sudo "$(command -v bluetooth-setup)"
```

## 8. Battery charge limits

No package needed: the `dell_laptop` kernel driver controls charging. The
limits are set in `home.nix` (`battery`: stop at 80%, start again below
75%, for a laptop that is mostly plugged in). Writing them needs root:

```sh
battery-setup   # alias for: sudo "$(command -v battery-setup)"
```

It applies the limits now and installs `/etc/tmpfiles.d/battery-charge.conf`,
which reapplies them at every boot. Rerun it after changing the limits.
Dell firmware only allows a start of 50–95% and a stop of 55–100%, at least
5 apart. To check: `cat /sys/class/power_supply/BAT0/charge_*`.

To charge to 100% once, e.g. before a trip, run
`battery-full` (a shell alias that runs it with sudo), which sets the limits
to 95–100%. It lasts until the next boot, or until `battery-setup` is run
again. Back on the normal limits, the bar shows a yellow `unplug` while the
battery is above the stop limit: the firmware can't discharge it, so unplug
until it is back under 80%.

## Optional: zsh as the login shell

zsh is installed and configured by Home Manager, but the login shell is still
`/usr/bin/bash`. To switch, add the Nix zsh to `/etc/shells` and `chsh`:

```sh
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

## All at once

Everything above after the base system, in one command:

```sh
sudo pacman -S --needed nix xorg-server xorg-xinit mesa xf86-video-nouveau \
  vulkan-nouveau lightdm lightdm-slick-greeter papirus-icon-theme i3lock \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
  gst-plugin-pipewire libpulse networkmanager wpa_supplicant bluez \
  bluez-utils power-profiles-daemon
```

Then do the setup steps from sections 2, 4, 7 and 8.
