{pkgs, lib, ...}: {

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
        #heroic
        #lutris
        goverlay
        mangohud
        protonup
        #bottles

        # Others
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
        libvdpau-va-gl
        restic 
    ];

    environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    programs = {
        gamemode.enable = true;
        steam = {
            enable = true;
            gamescopeSession.enable = true;
        };
    };

}   