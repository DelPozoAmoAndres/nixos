{
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_1TB_S5SVNF0NB92660R";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF02";
            };
            ESP = {
              size = "4G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "luks_btrfs";
                #passwordFile = "/tmp/secret.key";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Override existing partition
                  subvolumes = {
                    "/rootfs" = {
                      mountpoint = "/";
                    };
                    "/home" = {
                      # SIN compress=zstd: penaliza 3-4x las escrituras de
                      # muchos ficheros pequenos (instalar juegos, builds).
                      # Ver modules/storage.nix para la medicion.
                      mountOptions = ["noatime"];
                      mountpoint = "/home";
                    };
                    "/home/pozito" = {};
                    "/nix" = {
                      mountOptions = ["noatime"];
                      mountpoint = "/nix";
                    };
                  };
                  mountpoint = "/partition-root";
                };
              };
            };
          };
        };
      };
    };
  };
}

