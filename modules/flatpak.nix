{pkgs, lib, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        flatpak
        gnome.gnome-software
    ];

    services.flatpak.enable = true;
    systemd.services.flatpak-repo = {
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
    };
}   