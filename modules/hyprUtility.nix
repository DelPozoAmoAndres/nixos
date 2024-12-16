{pkgs, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        ulauncher 
        nautilus
        waybar
        pulseaudio
        pavucontrol
        kitty
        hyprpaper
        hyprlock
        (pkgs.writeShellScriptBin "hyprexit" ''
            ${hyprland}/bin/hyprctl dispatch exit
            ${systemd}/bin/loginctl terminate-user "alnav"
        '')
        hyprshot
        sway
        playerctl
    ];

    programs = {
        hyprland = {    
            enable = true;    
            xwayland.enable = true;
        };
    };
}         