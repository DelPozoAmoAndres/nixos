{ config, lib, pkgs, ... }:

{
  # Vanilla: zen causabapantalla negra tras LUKS.
  boot.kernelPackages = pkgs.linuxPackages;

  environment.systemPackages = with pkgs; [
    lutris
    goverlay
    mangohud
    gamescope
    protonup-ng
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
    gamemode = {
      enable = true;
      settings = {
        cpu = {
          governor = "performance";
        };
      };
    };
    gamescope = {
      capSysNice = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      gamescopeSession = {
        enable = true;
        args = [
          "--expose-wayland"
          "--rt"
          "--prefer-vk-device" "10de"
          "--adaptive-sync"
        ];
        env = {
          ENABLE_GAMESCOPE_WSI = "1";
          DXVK_ASYNC = "1";
          PROTON_ENABLE_NVAPI = "1";
          PROTON_HIDE_NVIDIA_GPU = "0";
        };
      };
    };
  };
}
