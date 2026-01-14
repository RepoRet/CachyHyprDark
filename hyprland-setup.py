import subprocess
import os
import sys
import shutil
import re

# Colored output helpers
def print_color(text, color='green'):
    colors = {'green': '\033[92m', 'yellow': '\033[93m', 'red': '\033[91m', 'reset': '\033[0m'}
    print(f"{colors[color]}{text}{colors['reset']}")

def run_cmd(cmd, sudo=False, capture_output=False):
    prefix = ['sudo'] if sudo else []
    try:
        if capture_output:
            return subprocess.check_output(prefix + cmd.split()).decode('utf-8').strip()
        subprocess.check_call(prefix + cmd.split())
        return True
    except subprocess.CalledProcessError as e:
        print_color(f"Error running '{cmd}': {e}", 'red')
        return False

def pkg_installed(pkg):
    return subprocess.call(['pacman', '-Qi', pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0

def install_pkgs(pkgs, sudo=True):
    to_install = [pkg for pkg in pkgs if not pkg_installed(pkg)]
    if to_install:
        cmd = f'pacman -S --noconfirm {" ".join(to_install)}'
        return run_cmd(cmd, sudo=sudo)
    return True

def prompt_yes_no(question, default='n'):
    resp = input(f"{question} (y/N): ").lower() or default
    return resp == 'y'

def detect_gpu():
    lspci_out = run_cmd('lspci', capture_output=True)
    if 'NVIDIA' in lspci_out.upper():
        return 'nvidia'
    elif 'AMD' in lspci_out.upper() or 'ATI' in lspci_out.upper():
        return 'amd'
    return None

def main():
    # Ensure rsync for theme sync
    install_pkgs(['rsync'])

    # Update system
    print_color("Updating system...")
    run_cmd('pacman -Syu --noconfirm', sudo=True)

    # Core packages
    print_color("Installing core packages...")
    core_pkgs = [
        'hyprland', 'waybar', 'kitty', 'rofi-wayland', 'dunst', 'swaylock', 'wlogout', 'swww',
        'nwg-look', 'lxappearance', 'qt6ct', 'adwaita-qt6', 'ttf-nerd-fonts-symbols',
        'wl-clipboard', 'cliphist', 'polkit-gnome',
        'pipewire', 'pipewire-pulse', 'pipewire-alsa', 'pipewire-jack', 'wireplumber'
    ]
    install_pkgs(core_pkgs)

    # Theme setup (rsync with --delete)
    print_color("Deploying dark theme...")
    theme_src = './themes/dark/'
    theme_dest = os.path.expanduser('~/.config/hypr/themes/dark/')
    os.makedirs(theme_dest, exist_ok=True)
    run_cmd(f'rsync -av --delete {theme_src} {theme_dest}')

    # Symlinks for configs (skip if exist)
    configs = ['waybar', 'kitty', 'rofi', 'dunst', 'swaylock', 'wlogout']
    for config in configs:
        src = os.path.join(theme_dest, config)
        dest = os.path.expanduser(f'~/.config/{config}')
        if not os.path.exists(dest):
            os.symlink(src, dest)
            print_color(f"Symlinked {config}")

    # Copy hyprland.conf if missing (assume it sources theme.conf)
    conf_dest = os.path.expanduser('~/.config/hypr/hyprland.conf')
    if not os.path.exists(conf_dest):
        shutil.copy('hyprland.conf', conf_dest)
        print_color("Copied starter hyprland.conf")

    # Optional gaming
    if prompt_yes_no("Install gaming packages (steam, obs-studio, vulkan loaders)?"):
        gaming_pkgs = ['steam', 'obs-studio', 'vulkan-icd-loader', 'lib32-vulkan-icd-loader']
        install_pkgs(gaming_pkgs)

    # Multimedia defaults
    print_color("Setting up multimedia...")
    media_pkgs = ['mpv', 'swayimg']
    install_pkgs(media_pkgs)
    # Set MIME defaults (example for video/image)
    run_cmd('xdg-mime default mpv.desktop video/mp4')
    run_cmd('xdg-mime default swayimg.desktop image/png')  # Adjust types as needed

    # GPU drivers
    gpu = detect_gpu()
    if gpu:
        print_color(f"Detected {gpu.upper()} GPU.")
        if gpu == 'nvidia' and prompt_yes_no("Install NVIDIA drivers?"):
            install_pkgs(['nvidia', 'nvidia-utils'])
        elif gpu == 'amd' and prompt_yes_no("Install AMD drivers?"):
            install_pkgs(['mesa', 'vulkan-radeon', 'lib32-vulkan-radeon'])
    else:
        print_color("No GPU detected; skipping drivers.", 'yellow')

    # SDDM setup
    print_color("Setting up SDDM...")
    install_pkgs(['sddm'])
    desktop_file = '/usr/share/wayland-sessions/hyprland.desktop'
    if not os.path.exists(desktop_file):
        content = """
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Compositor
Exec=Hyprland
Type=Application
"""
        with open('/tmp/hyprland.desktop', 'w') as f:
            f.write(content)
        run_cmd(f'mv /tmp/hyprland.desktop {desktop_file}', sudo=True)
        run_cmd('chmod 644 {desktop_file}', sudo=True)
    run_cmd('systemctl enable sddm', sudo=True)

    # Optional autologin
    if prompt_yes_no("Enable autologin for current user?"):
        autologin_dir = '/etc/sddm.conf.d/'
        os.makedirs(autologin_dir, exist_ok=True)
        content = f"""
[Autologin]
User={os.getlogin()}
Session=hyprland.desktop
"""
        autologin_file = os.path.join(autologin_dir, 'autologin.conf')
        with open('/tmp/autologin.conf', 'w') as f:
            f.write(content)
        run_cmd(f'mv /tmp/autologin.conf {autologin_file}', sudo=True)

    # Final instructions
    print_color("Setup complete! Final steps:")
    print("- Edit ~/.config/hypr/hyprland.conf as needed (sources theme.conf).")
    print("- Wallpaper: Ensure swww line in conf points to ~/.config/hypr/themes/dark/wallpaper/wallpaper.png.")
    print("- Reboot to start Hyprland via SDDM.")
    print("- Troubleshoot: Check Arch Wiki (hyprland, sddm) or CachyOS forums.")

    if prompt_yes_no("Reboot now?"):
        run_cmd('reboot', sudo=True)

if __name__ == '__main__':
    main()