{ config, lib, pkgs, ... }:

{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pulseaudio.enable = false;
    udisks2 = {
      enable = true;
      settings."udisks2.conf".defaults.filesystem_short_names = "true";
    };
    gvfs.enable = true;
    usbmuxd = {
      enable = true;
      package = pkgs.usbmuxd2;
    };
  };

  # Acceso a dispositivos iOS y utilidades USB
  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
    usbutils
  ];
}
