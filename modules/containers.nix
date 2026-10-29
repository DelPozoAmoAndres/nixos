{ config, lib, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    # Escribe /etc/nvidia-container-runtime/config.toml en modo cdi y registra
    # el runtime nvidia con la ruta real del store. Sin esto, "docker run
    # --gpus all" falla con "CDI spec not found".
    enableNvidia = true;
    daemon.settings = {
      # local en vez de journald: logs con rotacion y limite de tamano.
      "log-driver" = "local";
      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };
      "max-concurrent-downloads" = 10;
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--filter" "until=168h" ];
    };
  };
}
