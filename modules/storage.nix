{ config, lib, pkgs, ... }:

{
  # Override del montaje de la raiz para NOTificar subvol=/rootfs.
  # Hace que el initrd monte el arbol btrfs completo, que es lo que
  # funciona con el arranque actual. El montaje separado de /nix en el
  # initrd (con x-initrd.mount) deja la pantalla en negro con _.
  #
  # "compress=zstd" es importante: Btrfs guarda la compression POR
  # SUBVOLUMEN, y cuando un subvolumen anidado (como /home) se monta
  # encima de un padre ya montado, su opcion "compress" se IGNORA
  # (el kernel no puede cambiar la compression de un subvolumen que ya
  # esta montado). Por eso /home estaba sin comprimir aunque el fstab
  # lo pidiera.
  #
  # Al comprimir tambien la raiz, los subvolumenes anidados heredan
  # zstd y el espacio se recupera de verdad.
  fileSystems."/" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "x-initrd.mount" "compress=zstd" "noatime" ];
  };

  # /home y /nix se montan aparte (son subvolumenes anidados), asi que
  # necesitan su propia opcion de compresion.
  fileSystems."/home" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "subvol=/home" ];
  };

  fileSystems."/nix" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "subvol=/nix" ];
  };

  systemd.timers.fstrim.enable = true;
}
