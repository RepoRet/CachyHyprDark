import subprocess
import os
import shutil
import sys

def run_cmd(cmd, sudo=False):
    prefix = ['sudo'] if sudo else []
    try:
        subprocess.check_call(prefix + cmd.split())
    except subprocess.CalledProcessError as e:
        print(f"Error running '{cmd}': {e}")
        sys.exit(1)

def main():
    # Update system
    run_cmd('pacman -Syu --noconfirm', sudo=True)
    
    # Install core packages (check if installed first)
    core_pkgs = 'hyprland waybar kitty rofi-wayland dunst swaylock wlogout swww pipewire wireplumber'.split()
    to_install = [pkg for pkg in core_pkgs if subprocess.call(['pacman', '-Qi', pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0]
    if to_install:
        run_cmd(f'pacman -S --noconfirm {" ".join(to_install)}', sudo=True)
    
    # Theme setup (rsync embedded theme)
    theme_src = './themes/dark/'
    theme_dest = os.path.expanduser('~/.config/hypr/themes/dark/')
    os.makedirs(theme_dest, exist_ok=True)
    shutil.copytree(theme_src, theme_dest, dirs_exist_ok=True)  # Or use rsync via subprocess
    
    # Symlinks (e.g., for waybar, kitty, etc.)
    configs = ['waybar', 'kitty', 'rofi', 'dunst', 'swaylock', 'wlogout']
    for config in configs:
        src = os.path.join(theme_dest, config)
        dest = os.path.expanduser(f'~/.config/{config}')
        if not os.path.exists(dest):
            os.symlink(src, dest)
    
    # Copy hyprland.conf if missing
    conf_dest = os.path.expanduser('~/.config/hypr/hyprland.conf')
    if not os.path.exists(conf_dest):
        shutil.copy('hyprland.conf', conf_dest)
    
    # ... Add GPU detection (use lspci via subprocess), optional installs, SDDM setup, etc.
    
    # Final: Optional reboot
    if input("Reboot now? (y/N): ").lower() == 'y':
        run_cmd('reboot', sudo=True)

if __name__ == '__main__':
    main()