{ config, lib, pkgs, ... }:

{
  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
  };

  users.groups = {
    libvirtd.members = [ "pozito" ];
    vboxusers.members = [ "pozito" ];
  };

  environment.systemPackages = with pkgs; [
    quickemu
    virt-viewer
  ];
}
