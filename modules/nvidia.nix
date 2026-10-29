{ config, lib, pkgs, ... }:

{
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      nvidiaSettings = true;
      open = false;
      # Mantiene la GPU inicializada: menos latencia al lanzar juegos o
      # cargas de trabajo de IA, y no reinicia el driver al suspender.
      nvidiaPersistenced = true;
      powerManagement = {
        enable = true;
        # finegrained activa DynamicPowerManagement: la GPU baja relojes de
        # forma agresiva. Se deja desactivado para no meter stutter.
        finegrained = false;
      };
    };
    nvidia-container-toolkit = {
      enable = true;
    };
    graphics.extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    nvidia-docker
  ];
}
