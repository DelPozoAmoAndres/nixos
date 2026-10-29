{ config, lib, pkgs, ... }:

{
  # Override del montaje de la raiz para NOTificar subvol=/rootfs.
  # Hace que el initrd monte el arbol btrfs completo, que es lo que
  # funciona con el arranque actual. El montaje separado de /nix en el
  # initrd (con x-initrd.mount) deja la pantalla en negro con _.
  fileSystems."/" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "x-initrd.mount" ];
  };

  fileSystems."/nix" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "subvol=/nix" ];
  };

  systemd.timers.fstrim.enable = true;
}
