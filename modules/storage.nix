{ config, lib, pkgs, ... }:

{
  # Override del montaje de la raiz para NOTificar subvol=/rootfs.
  # Hace que el initrd monte el arbol btrfs completo, que es lo que
  # funciona con el arranque actual. El montaje separado de /nix en el
  # initrd (con x-initrd.mount) deja la pantalla en negro con _.
  #
  # SIN COMPRESION (compress=zstd), a proposito.
  #
  # Se probo y se descarto. La compresion zstd da entre un 25 y un 30% de
  # ahorro en los datos de texto y codigo, pero penaliza MUCHO las
  # escrituras de muchos ficheros pequenos, que es el patron de Steam
  # al instalar juegos (miles de .vpk y .pak) y de cualquier build:
  #
  #   3000 ficheros de 4 KB -> con zstd:    5855 ms
  #                       -> sin zstd:   1430-1963 ms
  #
  # Es decir, 3-4 veces mas lento. Con la compresion activada, una
  # simple descarga de Steam saturaba el disco (I/O pressure al 98%,
  # load average de 50) y el equipo se arrastraba.
  #
  # El espacio en disco no es el problema: con 927 GB y 124 GB libres
  # (mas lo que se recuperare al borrar la cache de Go y hacer GC del
  # store) hay de sobra. El rendimiento si importa.
  #
  # Si alguna vez hace falta el espacio, la via correcta es limpiar la
  # cache y hacer GC del store de Nix, no comprimir el disco.
  fileSystems."/" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "x-initrd.mount" "noatime" ];
  };

  # /home y /nix se montan aparte (son subvolumenes anidados).
  fileSystems."/home" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "noatime" "subvol=/home" ];
  };

  fileSystems."/nix" = lib.mkForce {
    device = "/dev/mapper/luks_btrfs";
    fsType = "btrfs";
    options = [ "noatime" "subvol=/nix" ];
  };

  systemd.timers.fstrim.enable = true;
}
