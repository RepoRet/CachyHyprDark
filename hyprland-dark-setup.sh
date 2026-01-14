#!/usr/bin/env bash

# hyprland-dark-setup.sh
# Purpose: Automate post-install setup on minimal CachyOS (TTY/no GUI) to create a dark-themed Hyprland desktop
# Run as regular user from cloned repo directory[](https://github.com/RepoRet/CachyHyprDark.git)
# Idempotent: safe to re-run, skips existing packages/files/symlinks
# Updated 2026 edition: improved error handling, AUR detection, added xdg-portal, better prompts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hyprland Dark Setup for CachyOS (2026 Updated) ===${NC}"
echo "This script installs deps, applies dark theme, sets up SDDM, MIME defaults, etc."
echo "Assumes cloned repo with ./themes/dark/ and hyprland.conf present."
echo "Re-run safe. Skips existing items."
echo

# Check if running from repo dir (look for themes/dark/)
if [ ! -d "./themes/dark" ] || [ ! -f "./hyprland.conf" ]; then
    echo -e "${RED}Error: Must run from cloned repo directory (contains themes/dark/ and hyprland.conf).${NC}"
    exit 1
fi

# Helper: check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper: install package list if any missing (pacman)
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

# Helper: install AUR package if missing (prefers paru > yay)
install_aur_if_missing() {
    local pkg="$1"
    if pacman -Qq "$pkg" &>/dev/null; then
        echo -e "${GREEN}$pkg already installed.${NC}"
        return 0
    fi

    if command_exists paru; then
        echo -e "${YELLOW}Installing $pkg via paru...${NC}"
        paru -S --noconfirm "$pkg"
    elif command_exists yay; then
        echo -e "${YELLOW}Installing $pkg via yay...${NC}"
        yay -S --noconfirm "$pkg"
    else
        echo -e "${RED}No AUR helper (paru/yay) found. Skipping $pkg.${NC}"
        return 1
    fi
}

# Step 0: Update system
echo -e "${BLUE}→ Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Step 1: Core packages
echo -e "${BLUE}→ Installing core Hyprland & Wayland packages...${NC}"
core_packages=(
    hyprland
    xdg-desktop-portal-hyprland  # Added: fixes many app portals
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

# Step 2: Audio stack
echo -e "${BLUE}→ Installing Pipewire audio stack...${NC}"
audio_packages=(
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
)

install_if_missing "${audio_packages[@]}"

# Step 3: Optional hyprtheme build (requires rust)
build_hyprtheme=false
if command_exists rustc; then
    echo -e "${YELLOW}Rust detected. Build & install hyprtheme? (y/N)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        build_hyprtheme=true
    fi
else
    echo -e "${YELLOW}Rust not found. Skipping hyprtheme (install rust to enable).${NC}"
fi

if $build_hyprtheme; then
    echo -e "${BLUE}→ Building hyprtheme from source...${NC}"
    tmpdir=$(mktemp -d)
    git clone https://github.com/alexjercan/hyprtheme.git "$tmpdir"
    cd "$tmpdir"
    cargo install --path .
    cd - >/dev/null
    rm -rf "$tmpdir"
    echo -e "${GREEN}hyprtheme installed.${NC}"
fi

# Step 4: Apply theme via rsync
echo -e "${BLUE}→ Applying dark theme to ~/.config/hypr/themes/dark/...${NC}"
mkdir -p ~/.config/hypr/themes/dark/
rsync -a --delete ./themes/dark/ ~/.config/hypr/themes/dark/
echo -e "${GREEN}Theme rsynced (overwrites changes in target).${NC}"

# Step 5: Create symlinks (skip if exist)
echo -e "${BLUE}→ Setting up symlinks for configs...${NC}"
link_targets=(
    "waybar:~/.config/waybar"
    "kitty:~/.config/kitty"
    "rofi:~/.config/rofi"
    "dunst:~/.config/dunst"
    "swaylock:~/.config/swaylock"
    "wlogout:~/.config/wlogout"
)

for pair in "${link_targets[@]}"; do
    src_dir="${pair%%:*}"
    target="${pair##*:}"
    src_path="$HOME/.config/hypr/themes/dark/$src_dir"

    if [ -d "$src_path" ] && [ ! -L "$target" ] && [ ! -e "$target" ]; then
        ln -s "$src_path" "$target"
        echo -e "${GREEN}Symlink created: $target -> $src_path${NC}"
    else
        echo -e "${YELLOW}Skipping symlink for $target (exists or not a dir).${NC}"
    fi
done

# Step 6: Copy hyprland.conf if missing
echo -e "${BLUE}→ Checking hyprland.conf...${NC}"
if [ ! -f ~/.config/hypr/hyprland.conf ]; then
    mkdir -p ~/.config/hypr/
    cp ./hyprland.conf ~/.config/hypr/hyprland.conf
    echo -e "${GREEN}hyprland.conf copied.${NC}"
else
    echo -e "${YELLOW}hyprland.conf exists — skipping copy.${NC}"
fi

# Step 7: Optional utilities
echo -e "${BLUE}→ Optional utilities${