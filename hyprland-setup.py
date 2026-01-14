import subprocess
import os
import sys
import shutil

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
    # Ensure rsync is available for theme deployment
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

    # Theme setup (rsync with --delete to ensure clean deployment)
    print_color("Deploying dark theme...")
    theme_src = './themes/dark/'
    theme_dest = os.path.expanduser('~/.config/hypr/themes/dark/')
    os.makedirs(theme_dest, exist_ok=True)
    run_cmd(f'rsync -av --delete {theme_src} {theme_dest}')

    # Create symlinks for themed configs (only if destination doesn't exist)
    configs = ['waybar', 'kitty', 'rofi', 'dunst', 'swaylock', 'wlogout']
    for config in configs:
        src = os.path.join(theme_dest, config)
        dest = os.path.expanduser(f'~/.config/{config}')
        if not os.path.exists(dest):
            os.symlink(src, dest)
            print_color(f"Symlinked {config}")

    # Copy starter hyprland.conf only if it doesn't exist
    conf_dest = os.path.expanduser('~/.config/hypr/hyprland.conf')
    if not os.path.exists(conf_dest):
        shutil.copy('hyprland.conf', conf_dest)
        print_color("Copied starter hyprland.conf")

    # Optional utilities
    if prompt_yes_no("Install utilities (brave-browser, samba, rustdesk-bin)?"):
        util_pkgs = ['brave-browser', 'samba']
        install_pkgs(util_pkgs)
        # rustdesk-bin is AUR → check for yay/paru
        if pkg_installed('yay') or pkg_installed('paru'):
            aur_helper = 'yay' if pkg_installed('yay') else 'paru'
            run_cmd(f'{aur_helper} -S --noconfirm rustdesk-bin')
        else:
            print_color("AUR helper (yay/paru) not found. Skipping rustdesk-bin.", 'yellow')
            print_color("To install manually later: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si", 'yellow')

    # Optional gaming packages
    if prompt_yes_no("Install gaming packages (steam, obs-studio, vulkan loaders)?"):
        gaming_pkgs = ['steam', 'obs-studio', 'vulkan-icd-loader', 'lib32-vulkan-icd-loader']
        install_pkgs(gaming_pkgs)

    # Multimedia + MIME defaults
    print_color("Setting up multimedia...")
    media_pkgs = ['mpv', 'swayimg']
    install_pkgs(media_pkgs)
    # Set some common MIME defaults (can be expanded)
    run_cmd('xdg-mime default mpv.desktop video/mp4 video/mkv video/webm')
    run_cmd('xdg-mime default swayimg.desktop image/png image/jpeg image/gif')

    # GPU drivers (auto-detect + prompt)
    gpu = detect_gpu()
    if gpu:
        print_color(f"Detected {gpu.upper()} GPU.")
        if gpu == 'nvidia' and prompt_yes_no("Install NVIDIA drivers?"):
            install_pkgs(['nvidia', 'nvidia-utils'])
        elif gpu == 'amd' and prompt_yes_no("Install AMD open-source drivers?"):
            install_pkgs(['mesa', 'vulkan-radeon', 'lib32-vulkan-radeon'])
    else:
        print_color("No discrete GPU detected; skipping driver installation.", 'yellow')

    # SDDM setup
    print_color("Setting up SDDM...")
    install_pkgs(['sddm'])
    desktop_file = '/usr/share/wayland-sessions/hyprland.desktop'
    if not os.path.exists(desktop_file):
        content = """[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Compositor
Exec=Hyprland
Type=Application
"""
        with open('/tmp/hyprland.desktop', 'w') as f:
            f.write(content)
        run_cmd(f'mv /tmp/hyprland.desktop {desktop_file}', sudo=True)
        run_cmd(f'chmod 644 "{desktop_file}"', sudo=True)
    run_cmd('systemctl enable sddm', sudo=True)

    # Optional autologin
    print_color("\nSDDM Autologin Setup (optional)")
    print("This will configure SDDM to automatically log in the selected user into Hyprland.")
    print("Useful for single-user machines; can be removed later by deleting /etc/sddm.conf.d/autologin.conf")
    
    if prompt_yes_no("Would you like to enable autologin?"):
        # Try to detect current user, but let user override
        default_user = os.getlogin()
        print_color(f"Detected current user: {default_user}", 'yellow')
        
        user_input = input(f"Enter username for autologin (press Enter to use '{default_user}'): ").strip()
        autologin_user = user_input if user_input else default_user
        
        # Quick validation: check if user exists
        if not run_cmd(f"id {autologin_user}", capture_output=True):
            print_color(f"Warning: User '{autologin_user}' does not seem to exist on the system.", 'red')
            if not prompt_yes_no("Continue anyway? (not recommended)"):
                print_color("Autologin setup skipped.")
                # Skip to final instructions
                goto_final = True  # We'll add a flag to skip reboot prompt if needed
            else:
                goto_final = False
        else:
            goto_final = False
        
        if not goto_final:
            print_color(f"Will configure autologin for user: {autologin_user}")
            print_color(f"Session: hyprland.desktop")
            
            if prompt_yes_no("Confirm and write config now?"):
                autologin_dir = '/etc/sddm.conf.d/'
                autologin_file = os.path.join(autologin_dir, 'autologin.conf')
                
                # Create directory if missing
                if not os.path.exists(autologin_dir):
                    run_cmd(f'mkdir -p {autologin_dir}', sudo=True)
                    run_cmd(f'chmod 755 {autologin_dir}', sudo=True)
                
                # Write the config safely with sudo tee
                content = f"""[Autologin]
User={autologin_user}
Session=hyprland.desktop
"""
                run_cmd(f"echo '{content}' | sudo tee {autologin_file} > /dev/null")
                run_cmd(f"sudo chmod 644 {autologin_file}")
                
                print_color(f"Autologin config created: {autologin_file}")
                print_color("You can disable later by removing this file or editing it.")
            else:
                print_color("Autologin setup cancelled.")
    else:
        print_color("Autologin skipped.")

    # Final instructions
    print_color("\nSetup complete!", 'green')
    print("Final steps & recommendations:")
    print("  • Edit ~/.config/hypr/hyprland.conf if needed")
    print("    (should already source ~/.config/hypr/themes/dark/theme.conf)")
    print("  • Verify wallpaper command in hyprland.conf:")
    print("      exec-once = swww init && swww img ~/.config/hypr/themes/dark/wallpaper/wallpaper.png")
    print("  • Reboot to launch Hyprland via SDDM")
    print("  • Troubleshooting: Arch Wiki (Hyprland / SDDM), CachyOS forums, or ~/.config/hypr/logs")

    if prompt_yes_no("Reboot now to start Hyprland?"):
        run_cmd('reboot', sudo=True)

if __name__ == '__main__':
    main()