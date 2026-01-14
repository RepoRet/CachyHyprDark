# CachyHyprDark – Hyprland + Dark Theme Setup for CachyOS

One-click-ish post-install setup script that transforms a minimal **CachyOS** installation into a beautiful, performant **Hyprland** desktop with an embedded dark/minimal theme (heavily inspired by and forked from [alexjercan/darker-hyprland-theme](https://github.com/alexjercan/darker-hyprland-theme)).

**Credits**  
Theme assets and concepts are based on the excellent work by [@alexjercan](https://github.com/alexjercan) in the original darker-hyprland-theme repository.  
This version embeds the theme files directly, removes the original install/load/cleanup scripts, and consolidates everything into a single setup script for easier maintenance and future customization.

## Features

- Full Hyprland + Wayland setup on CachyOS
- Embedded dark/minimal theme (no external git clone at runtime)
- Themed configs for: Waybar, Kitty, Rofi, Dunst, Swaylock, Wlogout
- MPV as default video player + swayimg as simple image viewer
- Optional installs: Brave, RustDesk, Samba, Steam, OBS
- GPU driver detection & prompt (NVIDIA / AMD)
- SDDM with optional autologin
- Safe config handling: only creates `hyprland.conf` if it doesn't exist

## Repository Structure
CachyHyprDark/
├── hyprland-dark-setup.sh          # Main installation script – run this!
├── hyprland.conf                   # Starter config template (copied only if missing)
├── README.md                       # This file
    └── themes/
        └── dark/                       # Embedded theme files (forked & modified)
	    ├── dunst/                  # Notification theme
	    ├── kitty/                  # Terminal theme
	    ├── rofi/                   # Launcher theme
	    ├── swaylock/               # Lock screen theme
	    ├── wallpaper/              # Background image(s)
	    ├── waybar/                 # Status bar theme
	    ├── wlogout/                # Logout menu theme
	    ├── theme.conf              # Hyprland color/border variables
	    ├── theme.toml              # Theme metadata (optional)

## Requirements

- Fresh/minimal **CachyOS** installation (preferably the latest ISO as of 2026)
- Internet connection during setup
- Run in **TTY** (after base install, before any desktop environment)

## Installation Steps

1. **Clone this repository** (from TTY or existing session)

   ```bash
   git clone https://github.com/RepoRet/CachyHyprDark.git
   cd CachyHyprDark

Make the script executableBashchmod +x hyprland-dark-setup.sh
Run the setup scriptBash./hyprland-dark-setup.sh
Answer the y/N prompts (optional apps, drivers, autologin, reboot)
The script will:
Update system & install core packages
Copy embedded theme files
Create symlinks for themed app configs
Set up starter hyprland.conf (only if missing)
Configure SDDM + Hyprland session
Install optional software if chosen
Set MPV/swayimg as defaults


Reboot when prompted (or manually sudo reboot)
Login → You should land directly in Hyprland (if autologin enabled) or select Hyprland at SDDM.

Default keybinds (from starter config):

Super + Q → open Kitty terminal
Super + Space → rofi app launcher
Super + Shift + R → reload Hyprland config
Super + L → lock screen
Super + C → close window
Super + Shift + Q → exit Hyprland

Customization
After first run, edit these files freely:

Main config: ~/.config/hypr/hyprland.conf
Add monitor lines, change animations, more binds, window rules, etc.
Wallpaper command: look for the swww img line – update path/filename if your wallpaper file is different

Theme variables: ~/.config/hypr/themes/dark/theme.conf
Colors, borders, shadows, rounding, etc.

App-specific styles: ~/.config/hypr/waybar/, kitty/, etc. (symlinked to theme folder)

Future script runs will not overwrite your hyprland.conf or theme files.
Troubleshooting

Wallpaper not showing?
Check exact filename in ~/.config/hypr/themes/dark/wallpaper/ and update the swww img path in hyprland.conf.
Theme colors not applying?
Make sure source = ~/.config/hypr/themes/dark/theme.conf is at the top of hyprland.conf.
Missing icons/fonts?
ttf-nerd-fonts-symbols should be installed – if not, sudo pacman -S ttf-nerd-fonts-symbols
NVIDIA issues?
Re-run script and choose to install nvidia drivers, or manually install nvidia-dkms if using a custom kernel.
More help: Arch Wiki (Hyprland page), CachyOS forums, Hyprland Discord

License
This repository combines original work with a fork of darker-hyprland-theme.
See themes/dark/LICENSE for the original theme license.
Everything added/modified here follows the same spirit (usually MIT or equivalent).
Enjoy your clean, dark, performant Hyprland setup on CachyOS!
Feedback / PRs welcome.

— RepoRet (@RepoRet)