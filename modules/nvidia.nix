{config, pkgs, ...}: {
    
    environment.variables = {
        GBM_BACKEND = "nvidia-drm";
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    hardware = {
        nvidia = {
            modesetting.enable = true;
            powerManagement.enable = true;
            package = config.boot.kernelPackages.nvidiaPackages.latest;
            nvidiaSettings = true;
            powerManagement.finegrained = false;
            open = true;
        };
        graphics = {
            extraPackages = with pkgs; [
                nvidia-vaapi-driver
                vaapiVdpau
                libvdpau-va-gl
            ];
            enable32Bit = true;
            enable = true;
        };
        nvidia-container-toolkit = {
            enable = true;
        };
    };

    services.xserver = {
        enable = true;
        videoDrivers = ["nvidia"];
        displayManager = {
            gdm = {
                enable = true;
                wayland = true;
            };
        };
        wacom.enable = true;
    };
}