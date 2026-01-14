#!/usr/bin/env bash

# cachy-hypr-deps-install.sh
# Purpose: Install Hyprland + Wayland essentials + audio + QoL on minimal CachyOS (no theme/config apply)
# Designed to be re-runnable and safe
# Run as regular user from any directory

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== CachyOS Hyprland Dependencies Installer (2026 edition) ===${NC}"
echo "This script installs packages only — no configs, themes, SDDM, or MIME changes."
echo "Re-run safe. Skips already installed packages."
echo

# Helper: check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper: install package list if any missing
install_if_missing() {
    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        echo -e "${GREEN}All requested packages already installed.${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing: ${to_install[*]}${NC}"
    sudo pacman -S --needed --noconfirm "${to_install[@]}"
}

# Step 0: Update system
echo -e "${BLUE}→ Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Step 1: Core Hyprland + Wayland stack
echo -e "${BLUE}→ Installing core Hyprland & Wayland packages...${NC}"
core_packages=(
    hyprland
    xdg-desktop-portal-hyprland
    waybar
    kitty
    rofi-wayland
    dunst
    swaylock
    wlogout
    swww
    nwg-look
    lxappearance
    qt6ct
    adwaita-qt6
    ttf-nerd-fonts-symbols
    wl-clipboard
    cliphist
    polkit-gnome
)

install_if_missing "${core_packages[@]}"

# Step 2: Audio (Pipewire full stack)
echo -e "${BLUE}→ Installing Pipewire audio stack...${NC}"
audio_packages=(
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
)

install_if_missing "${audio_packages[@]}"

# Step 3: Optional – build hyprtheme? (requires rust)
build_hyprtheme=false
if command_exists rustc; then
    echo -e "${YELLOW}Rust detected — would you like to build & install hyprtheme? (y/N)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        build_hyprtheme=true
    fi
else
    echo -e "${YELLOW}Rust not found — skipping hyprtheme build (install rust if desired).${NC}"
fi

if $build_hyprtheme; then
    echo -e "${BLUE}→ Building hyprtheme from source...${NC}"
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://github.com/alexjercan/hyprtheme.git "$tmpdir"
    cd "$tmpdir"
    cargo install --path .
    cd - >/dev/null
    rm -rf "$tmpdir"
    echo -e "${GREEN}hyprtheme installed.${NC}"
fi

# Step 4: Optional groups
echo
echo -e "${BLUE}→ Optional packages${NC}"

# Utilities
echo -e "${YELLOW}Install utilities? (brave-browser, samba, rustdesk-bin via AUR) (y/N)${NC}"
read -r utils_choice
if [[ "$utils_choice" =~ ^[Yy]$ ]]; then
    utils_official=(brave-browser samba)
    install_if_missing "${utils_official[@]}"

    if ! pacman -Qq rustdesk-bin &>/dev/null; then
        if ! command_exists yay && ! command_exists paru; then
            echo -e "${RED}No AUR helper found (yay/paru). Skipping rustdesk-bin.${NC}"
        else
            echo -e "${YELLOW}Installing rustdesk-bin via AUR...${NC}"
            if command_exists paru; then
                paru -S --noconfirm rustdesk-bin
            else
                yay -S --noconfirm rustdesk-bin
            fi
        fi
    fi
fi

# Gaming
echo -e "${YELLOW}Install gaming packages? (steam, obs-studio, vulkan-icd-loader + lib32) (y/N)${NC}"
read -r gaming_choice
if [[ "$gaming_choice" =~ ^[Yy]$ ]]; then
    gaming_packages=(steam obs-studio vulkan-icd-loader lib32-vulkan-icd-loader)
    install_if_missing "${gaming_packages[@]}"
fi

# Step 5: GPU drivers
echo -e "${BLUE}→ GPU detection & driver install${NC}"
gpu_info=$(lspci | grep -E "VGA|3D" | tr '[:upper:]' '[:lower:]')

nvidia=false
amd=false

if echo "$gpu_info" | grep -q nvidia; then
    nvidia=true
    echo -e "${YELLOW}NVIDIA GPU detected.${NC}"
elif echo "$gpu_info" | grep -q "amd\|ati\|radeon"; then
    amd=true
    echo -e "${YELLOW}AMD GPU detected.${NC}"
else
    echo -e "${YELLOW}No clear NVIDIA/AMD GPU detected (Intel?). Skipping driver prompt.${NC}"
fi

if $nvidia; then
    echo -e "${YELLOW}Install NVIDIA drivers? (nvidia + nvidia-utils) (y/N)${NC}"
    read -r nvidia_choice
    if [[ "$nvidia_choice" =~ ^[Yy]$ ]]; then
        install_if_missing nvidia nvidia-utils
    fi
fi

if $amd; then
    echo -e "${YELLOW}Install AMD Vulkan drivers? (mesa + vulkan-radeon + lib32) (y/N)${NC}"
    read -r amd_choice
    if [[ "$amd_choice" =~ ^[Yy]$ ]]; then
        install_if_missing mesa vulkan-radeon lib32-vulkan-radeon
    fi
fi

# Step 6: Multimedia defaults packages (mpv + swayimg)
echo -e "${BLUE}→ Installing multimedia viewers...${NC}"
media_packages=(mpv swayimg)
install_if_missing "${media_packages[@]}"

echo
echo -e "${GREEN}=== Dependency installation complete ===${NC}"
echo "Installed core Hyprland stack, audio, and selected optionals."
echo "Next steps (manual):"
echo "  1. Apply your theme/config/dotfiles (or run your original setup script for that)"
echo "  2. Configure SDDM if desired: sudo pacman -S sddm   then enable & create hyprland.desktop"
echo "  3. Reboot or start Hyprland manually"
echo
echo -e "${YELLOW}Reboot now? (y/N)${NC}"
read -r reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    sudo reboot
fi

exit 0