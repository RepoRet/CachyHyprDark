#!/usr/bin/env bash

# =============================================================================
# hyprland-dark-setup.sh
# =============================================================================
# One-stop post-install script for CachyOS → Hyprland + embedded "dark" theme
# Repository: https://github.com/RepoRet/CachyHyprDark.git
# Credits: Theme files based on https://github.com/alexjercan/darker-hyprland-theme
#          (significant modifications planned – original scripts removed)
#
# Run this script as regular user from inside the cloned repo directory
# after a minimal CachyOS install (in TTY).
#
# Best practice: git clone the repo → cd into it → ./hyprland-dark-setup.sh
# =============================================================================

set -euo pipefail

# ────────────────────────────────────────────────
# Colored output helper
# ────────────────────────────────────────────────
cecho() { echo -e "\033[0;32m$1\033[0m"; }

# Error trap – basic cleanup message
trap 'echo -e "\033[0;31mError occurred. Aborting...\033[0m"; exit 1' ERR

# =============================================================================
# 1. System update
# =============================================================================
# Updates all packages before installing anything new
cecho "=== Updating system ==="
sudo pacman -Syu --noconfirm

# =============================================================================
# 2. Core Hyprland + utilities packages
# =============================================================================
# Edit this list to add/remove packages you always want installed
# Packages are checked before install → safe to re-run
cecho "=== Installing core Hyprland and utility packages ==="

core_packages=(
    hyprland waybar kitty rofi-wayland dunst swaylock wlogout swww
    nwg-look lxappearance qt6ct adwaita-qt6 ttf-nerd-fonts-symbols
    wl-clipboard cliphist polkit-gnome pipewire pipewire-pulse
    pipewire-alsa pipewire-jack wireplumber
)

for pkg in "${core_packages[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    fi
done

# =============================================================================
# 3. Rust → hyprtheme (optional theme manager)
# =============================================================================
# Still included in case you want to experiment with theme switching later
cecho "=== Installing Rust and building hyprtheme (if missing) ==="
if ! pacman -Qi rust &> /dev/null; then
    sudo pacman -S --noconfirm rust
fi

if ! command -v hyprtheme &> /dev/null; then
    git clone https://github.com/hyprland-community/hyprtheme.git /tmp/hyprtheme
    cd /tmp/hyprtheme
    make all
    sudo make install
    cd -
    rm -rf /tmp/hyprtheme
else
    cecho "hyprtheme already installed → skipping build"
fi

# =============================================================================
# 4. Copy embedded "dark" theme files from this repo
# =============================================================================
# Assumes you are running the script from inside the cloned repo folder
# Copies everything in ./themes/dark/ → ~/.config/hypr/themes/dark/
cecho "=== Copying embedded dark theme files ==="

THEME_SRC="$(pwd)/themes/dark"
THEME_DEST="$HOME/.config/hypr/themes/dark"

if [ ! -d "$THEME_SRC" ]; then
    echo "Error: themes/dark/ folder not found in current directory!"
    echo "Make sure you are running this script from inside the CachyHyprDark repo."
    exit 1
fi

mkdir -p "$HOME/.config/hypr/themes"
rsync -a --delete "$THEME_SRC/" "$THEME_DEST/"

cecho "Dark theme files copied to $THEME_DEST"

# =============================================================================
# 5. Create symlinks for themed app configs
# =============================================================================
# Symlinks let apps find the theme configs automatically
# You can change to cp -r instead of ln -s if you prefer independent copies
cecho "=== Creating symlinks to themed app configs ==="

apps=("waybar" "kitty" "rofi" "dunst" "swaylock" "wlogout")

for app in "${apps[@]}"; do
    src="$THEME_DEST/$app"
    dest="$HOME/.config/hypr/$app"
    if [ -d "$src" ]; then
        # Remove old symlink/dir if exists
        rm -rf "$dest"
        ln -sf "$src" "$dest"
        cecho "Symlinked $app → $src"
    else
        cecho "Warning: $app folder not found in theme → skipping"
    fi
done

# =============================================================================
# 6. Hyprland main config (only created if missing)
# =============================================================================
# Copies the template hyprland.conf from repo root if user doesn't have one yet
# This prevents overwriting customizations on future runs
CONFIG_DEST="$HOME/.config/hypr/hyprland.conf"

if [ ! -f "$CONFIG_DEST" ]; then
    cecho "=== Creating starter hyprland.conf (only because it didn't exist) ==="
    mkdir -p "$HOME/.config/hypr"
    cp "$(pwd)/hyprland.conf" "$CONFIG_DEST"
    cecho "Starter config copied → edit ~/.config/hypr/hyprland.conf freely"
else
    cecho "hyprland.conf already exists → skipping copy (edit manually)"
fi

# =============================================================================
# 7. Optional applications (grouped prompts)
# =============================================================================
# Edit prompts, package names, or add new groups here
cecho "=== Optional applications installation ==="

read -r -p "Install Brave Browser, RustDesk, Samba? (y/N) " util_choice
if [[ "$util_choice" =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm brave-browser samba
    yay -S --noconfirm rustdesk-bin || cecho "yay not found or failed → install RustDesk manually"
    cecho "Samba installed. Later: sudo systemctl enable --now smb nmb"
fi

read -r -p "Install Steam + OBS Studio? (y/N) " game_choice
if [[ "$game_choice" =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm steam obs-studio vulkan-icd-loader lib32-vulkan-icd-loader
fi

# =============================================================================
# 8. Multimedia defaults (MPV video + swayimg images)
# =============================================================================
cecho "=== Installing MPV + swayimg and setting as defaults ==="
sudo pacman -S --noconfirm mpv swayimg

xdg-mime default mpv.desktop video/mp4 video/mpeg video/x-matroska video/webm video/x-msvideo
xdg-mime default swayimg.desktop image/png image/jpeg image/gif image/webp image/bmp

# =============================================================================
# 9. GPU driver prompt (NVIDIA / AMD)
# =============================================================================
cecho "=== GPU detection and driver prompt ==="
gpu_info=$(lspci | grep -iE 'vga|3d|display' || true)

if echo "$gpu_info" | grep -iq nvidia; then
    read -r -p "NVIDIA detected. Install proprietary drivers? (y/N) " nvidia_choice
    [[ "$nvidia_choice" =~ ^[Yy]$ ]] && sudo pacman -S --noconfirm nvidia nvidia-utils
elif echo "$gpu_info" | grep -iq amd; then
    read -r -p "AMD detected. Install open-source stack? (y/N) " amd_choice
    [[ "$amd_choice" =~ ^[Yy]$ ]] && sudo pacman -S --noconfirm mesa vulkan-radeon lib32-vulkan-radeon
fi

# =============================================================================
# 10. SDDM + Hyprland session
# =============================================================================
cecho "=== Configuring SDDM for Hyprland ==="
sudo bash -c 'cat << EOF > /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Session
Exec=Hyprland
Type=Application
EOF'

read -r -p "Enable SDDM autologin for user $USER? (y/N) " auto_choice
if [[ "$auto_choice" =~ ^[Yy]$ ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo bash -c "cat << EOF > /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland.desktop
EOF"
fi

# =============================================================================
# 11. Final messages & reboot prompt
# =============================================================================
cecho "=== Setup complete! ==="
cecho "Next steps:"
cecho "  • Check wallpaper filename in ~/.config/hypr/themes/dark/wallpaper/"
cecho "    and edit swww img line in ~/.config/hypr/hyprland.conf if needed"
cecho "  • Customize binds, animations, monitors, etc. in ~/.config/hypr/hyprland.conf"
cecho "  • Re-login or reboot to start Hyprland"

read -r -p "Reboot now? (y/N) " reboot_choice
[[ "$reboot_choice" =~ ^[Yy]$ ]] && sudo reboot

cecho "Done. Enjoy your setup!"