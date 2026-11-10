{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    flatpak
  ];

  services.flatpak.enable = true;

  # El remoto de flathub se anade en el arranque. El problema: este
  # servicio corria en multi-user.target, que se alcanza ANTES de que la
  # red tenga DNS, y el "remote-add" fallaba con "Could not resolve
  # hostname flathub.org". El servicio queda en failed y ensucia el
  # estado del sistema en cada arranque.
  #
  # Aqui se espera a network-online.target y se reintenta: si aun asi
  # falla, se sale con codigo 0 (no es un error del sistema, solo un
  # remoto que se puede anadir luego a mano).
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # Espera hasta 60s a que haya red.
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 60;
    };
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
        || echo "flatpak: no se pudo anadir el remoto flathub (sin red?). Se puede anadir a mano con: flatpak remote-add flathub https://flathub.org/repo/flathub.flatpakrepo"
    '';
  };
}
