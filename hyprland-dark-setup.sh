#!/usr/bin/env bash

# setup-hyprland-darker.sh
# Post-install script for base CachyOS → Hyprland + darker-hyprland-theme
# Run as regular user after minimal CachyOS install (TTY login)
# Last major update: January 2026

set -euo pipefail

# ────────────────────────────────────────────────
# Colored output helper
# ────────────────────────────────────────────────
cecho() { echo -e "\033[0;32m$1\033[0m"; }

# Error trap
trap 'echo -e "\033[0;31mError occurred. Aborting...\033[0m"; exit 1' ERR

cecho "=== Updating system ==="
sudo pacman -Syu --noconfirm

cecho "=== Installing SDDM (display manager) ==="
if ! pacman -Qi sddm &> /dev/null; then
    sudo pacman -S --noconfirm sddm
    sudo systemctl enable sddm
else
    cecho "SDDM already installed."
fi

cecho "=== Installing Hyprland and core dependencies ==="
core_pkgs="hyprland waybar kitty rofi-wayland dunst swaylock wlogout swww \
           nwg-look lxappearance qt6ct adwaita-qt6 ttf-nerd-fonts-symbols \
           wl-clipboard cliphist polkit-gnome pipewire pipewire-pulse \
           pipewire-alsa pipewire-jack wireplumber"
for pkg in $core_pkgs; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    fi
done

cecho "=== Installing Rust for hyprtheme ==="
if ! pacman -Qi rust &> /dev/null; then
    sudo pacman -S --noconfirm rust
fi

cecho "=== Building and installing hyprtheme (if not present) ==="
if ! command -v hyprtheme &> /dev/null; then
    git clone https://github.com/hyprland-community/hyprtheme.git /tmp/hyprtheme
    cd /tmp/hyprtheme
    make all
    sudo make install
    cd -
    rm -rf /tmp/hyprtheme
else
    cecho "hyprtheme already installed."
fi

cecho "=== Cloning / updating darker-hyprland-theme ==="
mkdir -p ~/.config/hypr/themes
cd ~/.config/hypr/themes
if [ -d "darker" ]; then
    cecho "darker theme already exists → updating..."
    cd darker
    git pull
    cd ..
else
    git clone https://github.com/alexjercan/darker-hyprland-theme.git darker
fi
hyprtheme enable darker

# ────────────────────────────────────────────────
# Hyprland config — FULL REPLACEMENT with official example + darker theme
# ────────────────────────────────────────────────
cecho "=== Creating full Hyprland config (official example + darker theme) ==="

mkdir -p ~/.config/hypr

cat << 'EOF' > ~/.config/hypr/hyprland.conf
# Official Hyprland example config + darker-hyprland-theme integration
# https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.conf

source = ~/.config/hypr/themes/darker/theme.conf

# ────────────────────────────────────────────────
# STARTUP
# ────────────────────────────────────────────────
exec-once = waybar
exec-once = swww init
exec-once = swww img ~/.config/hypr/themes/darker/wallpaper/wallpaper.png
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# ────────────────────────────────────────────────
# ENVIRONMENT
# ────────────────────────────────────────────────
env = GTK_THEME,Adwaita:dark
env = QT_STYLE_OVERRIDE,adwaita-dark

# ────────────────────────────────────────────────
# INPUT
# ────────────────────────────────────────────────
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }
    sensitivity = 0
}

# ────────────────────────────────────────────────
# GENERAL
# ────────────────────────────────────────────────
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    layout = dwindle
}

# ────────────────────────────────────────────────
# DECORATION
# ────────────────────────────────────────────────
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
}

# ────────────────────────────────────────────────
# ANIMATIONS
# ────────────────────────────────────────────────
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# ────────────────────────────────────────────────
# DWINDLE
# ────────────────────────────────────────────────
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# ────────────────────────────────────────────────
# GESTURES
# ────────────────────────────────────────────────
gestures {
    workspace_swipe = on
}

# ────────────────────────────────────────────────
# MISC
# ────────────────────────────────────────────────
misc {
    force_default_wallpaper = -1
    disable_hyprland_logo = true
}

# ────────────────────────────────────────────────
# KEYBINDS
# ────────────────────────────────────────────────
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, Space, exec, rofi -show drun
bind = $mainMod SHIFT, R, exec, hyprctl reload
bind = $mainMod, L, exec, swaylock
bind = $mainMod, C, killactive,
bind = $mainMod, F, fullscreen,
bind = $mainMod SHIFT, Q, exit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
# ... up to 0 or add more

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
# ... similarly

# Example window rules
windowrulev2 = suppressevent maximize, class:.*
EOF

# ────────────────────────────────────────────────
# AUR helper (yay)
# ────────────────────────────────────────────────
cecho "=== Installing AUR helper (yay) if missing ==="
if ! command -v yay &> /dev/null; then
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# ────────────────────────────────────────────────
# Optional applications
# ────────────────────────────────────────────────
cecho "=== Optional applications ==="

cecho "Install RustDesk, Samba, Brave Browser? (y/N)"
read -r util_choice
if [[ "$util_choice" =~ ^[Yy]$ ]]; then
    yay -S --noconfirm rustdesk-bin
    sudo pacman -S --noconfirm samba brave-browser
    cecho "Samba installed. Later run: sudo systemctl enable --now smb nmb"
fi

cecho "Install Steam + OBS Studio? (y/N)"
read -r game_choice
if [[ "$game_choice" =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm steam obs-studio \
        vulkan-icd-loader lib32-vulkan-icd-loader
fi

# ────────────────────────────────────────────────
# Multimedia defaults (MPV + swayimg)
# ────────────────────────────────────────────────
cecho "=== Installing MPV and swayimg + setting defaults ==="
sudo pacman -S --noconfirm mpv swayimg

cecho "Setting MPV as default video player and swayimg as default image viewer..."
xdg-mime default mpv.desktop video/mp4 video/mpeg video/x-matroska video/webm video/x-msvideo
xdg-mime default swayimg.desktop image/png image/jpeg image/gif image/webp image/bmp

# ────────────────────────────────────────────────
# GPU drivers prompt
# ────────────────────────────────────────────────
cecho "=== GPU detection ==="
gpu_info=$(lspci | grep -iE 'vga|3d|display')
if echo "$gpu_info" | grep -iq nvidia; then
    cecho "NVIDIA GPU detected. Install proprietary drivers? (y/N)"
    read -r nvidia_choice
    [[ "$nvidia_choice" =~ ^[Yy]$ ]] && sudo pacman -S --noconfirm nvidia nvidia-utils
elif echo "$gpu_info" | grep -iq amd; then
    cecho "AMD GPU detected. Install open-source stack? (y/N)"
    read -r amd_choice
    [[ "$amd_choice" =~ ^[Yy]$ ]] && sudo pacman -S --noconfirm mesa vulkan-radeon lib32-vulkan-radeon
fi

# ────────────────────────────────────────────────
# SDDM Hyprland session
# ────────────────────────────────────────────────
cecho "=== Configuring SDDM Hyprland session ==="
sudo bash -c 'cat << EOF > /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Session
Exec=Hyprland
Type=Application
EOF'

cecho "Enable SDDM autologin for user $USER? (y/N)"
read -r auto_choice
if [[ "$auto_choice" =~ ^[Yy]$ ]]; then
    sudo bash -c "cat << EOF >> /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland.desktop
EOF"
fi

# ────────────────────────────────────────────────
# Final checks & reboot prompt
# ────────────────────────────────────────────────
cecho "=== Quick verification ==="
hyprtheme list || cecho "Warning: hyprtheme list failed"
systemctl is-enabled sddm && cecho "SDDM enabled" || cecho "SDDM not enabled?"

cecho "=== Setup complete! ==="
cecho "Reboot now to start Hyprland? (y/N)"
read -r reboot_choice
[[ "$reboot_choice" =~ ^[Yy]$ ]] && sudo reboot