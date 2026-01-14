# Hyprland + Dark Theme Setup for Baseline CachyOS

> [!CAUTION]
> **CRITIAL IMPORTANT** \
> EARLY BUILD - not ready for use. 

> [!WARNING]
> Script is in testing phase.

> [!IMPORTANT]
> Proceed at your own risk.

One-click-ish post-install setup script that transforms a minimal **CachyOS** installation into a beautiful, performant **Hyprland** desktop with an embedded dark/minimal theme.

<br/>

## Features

- Full Hyprland + Wayland setup on CachyOS
- Embedded dark/minimal theme (no external git clone at runtime)
- Themed configs for: Waybar, Kitty, Rofi, Dunst, Swaylock, Wlogout
- MPV as default video player + swayimg as simple image viewer
- Optional installs: Brave, RustDesk, Samba, Steam, OBS
- GPU driver detection & prompt (NVIDIA / AMD)
- SDDM with optional autologin
- Safe config handling: only creates `hyprland.conf` if it doesn't exist
<br/>

> [!IMPORTANT]
> ## Requirements
>- Fresh/minimal **[CachyOS](https://cachyos.org/)** installation tested on early 2026 ISO build (`cachyos-desktop-linux-251129.iso`).
>- Internet connection is required during setup.
>- Familiar with **CLI / TTY** (post basic CachyOS install)

<br/>

## Installation Steps

1. **Clone this repository** (from TTY or existing session)

   ```bash
   git clone https://github.com/RepoRet/CachyHyprDark.git
   ```
   
2. **Change Directory**
   ```bash
   cd CachyHyprDark
   ```
   
3. **Make Script Executable**
   ```bash
   pending
   ```
   
4. **Run Script**
   ```bash
   python hyprland-setup.py
   ```
   
**The script will automatically:** \
`/ Update the system and install core packages` \
`/ Copy the embedded dark theme files`
`/ Create symlinks for themed configs (Waybar, Kitty, Rofi, etc.)` \
`/ Create a starter hyprland.conf (only if it doesn't already exist)` \
`/ Set up SDDM with Hyprland session` \
`/ Configure MPV (video) + swayimg (images) as defaults`

**Follow the on-screen prompts**
- Answer y/N to install optional packages:
  - Brave Browser, RustDesk, Samba
  - Steam + OBS Studio
- Choose GPU drivers (NVIDIA / AMD) if detected
- Enable SDDM autologin (optional)
- Reboot when prompt

Login → You should land directly in Hyprland (if autologin enabled) or select Hyprland at SDDM.

<br/>

## Default keybinds (from starter config):
| Shortcut | Description |
| --- | --- |
| `Super + Q` | → open Kitty terminal |
| `Super + Space` | → rofi app launcher |
| `Super + Shift + R` | → reload Hyprland config |
| `Super + L` | → lock screen |
| `Super + C` | → close window |
| `Super + Shift + Q` | → exit Hyprland |
<br/>

## Customization
Future runs of the setup script will not overwrite your existing configuration files.
| File / Location | Purpose / What to Customize |
| --- | --- |
| `~/.config/hypr/hyprland.conf` | Keybinds, monitors, animations, gaps, layout, wallpaper path, window rules… |
| `~/.config/hypr/themes/dark/theme.conf` | Colors, borders, shadows, rounding, blur settings |
| `~/.config/hypr/waybar/`, `kitty/`, `rofi/`, etc | App-specific styles (symlinked from the theme folder) |
<br/>

## Wallpaper
If the background doesn't appear:
Check the exact filename inside `~/.config/hypr/themes/dark/wallpaper/`. \
Update the line in hyprland.conf 
```
exec-once = swww img ~/.config/hypr/themes/dark/wallpaper/your-wallpaper-file.png
```

<br/>

## Troubleshooting
| Issue | Solution / Check |
| --- | --- |
| Wallpaper not showing | Verify filename in `wallpaper/` folder and update `swww img` path in config. | 
| Theme colors not applied | Confirm `source = ~/.config/hypr/themes/dark/theme.conf` is at top of config. | 
| Missing icons or fonts | Install: `sudo pacman -S ttf-nerd-fonts-symbols`. |
| NVIDIA graphics issues | Re-run script and select NVIDIA drivers, or install `nvidia-dkms` manually. |

Need more help? \
• Arch Wiki – Hyprland \
• CachyOS forums \
• Hyprland Discord

<br/>

## Repository Structure
```
CachyHyprDark/
├── hyprland-setup.py               # Main installation script – run this!
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
        └── LICENSE                 # Original license & credits
```

> [!NOTE]
> License
> This repository combines original work with a fork of darker-hyprland-theme.
> See themes/dark/LICENSE for the original theme license.
> Everything added/modified here follows the same spirit (usually MIT or equivalent).
> Enjoy your clean, dark, performant Hyprland setup on CachyOS!
> Feedback / PRs welcome. \
> \
> **Credits**  
>Theme assets and concepts are based on the excellent work by [@alexjercan](https://github.com/alexjercan) in the original  [alexjercan/darker-hyprland-theme](https://github.com/alexjercan/darker-hyprland-theme) repository. This version embeds the theme files directly, removes the original install/load/cleanup scripts, and consolidates everything into a single setup script for easier maintenance and future customization.

— RepoRet (@RepoRet)
