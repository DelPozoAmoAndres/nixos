{pkgs, lib, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        libimobiledevice
        ifuse
        usbutils
    ];

    services.usbmuxd = {
        enable = true;
        package = pkgs.usbmuxd2;
    };

}   