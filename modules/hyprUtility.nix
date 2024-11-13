{pkgs, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        ulauncher 
        gnome.nautilus
        waybar
        pulseaudio
        pavucontrol
        kitty
        hyprpaper
        hyprlock
        hyprshot
        sway
    ];

    programs = {
        hyprland = {    
            enable = true;    
            xwayland.enable = true;
        };
    };
}         