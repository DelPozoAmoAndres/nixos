{pkgs, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        vesktop
        brave
        youtube-music
        telegram-desktop
        bitwarden
        remmina
    ];
}   