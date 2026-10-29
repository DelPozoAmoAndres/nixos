{ config, lib, user, pkgs, meta, inputs, ... }:

{
  imports = [
    ./modules/system.nix
    ./modules/storage.nix
    ./modules/hardware.nix
    ./modules/nvidia.nix
    ./modules/performance.nix
    ./modules/containers.nix
    ./modules/virtualization.nix
    ./modules/gaming.nix
    #./modules/ai.nix
    ./modules/desktop.nix
    ./modules/dev.nix
    ./modules/flatpak.nix
  ];

  # CA de la VPN corporativa. Ruta relativa al flake: mantiene la evaluacion
  # pura (sin --impure).
  security.pki.certificates = [
    (builtins.readFile ./rootCA.pem)
  ];

  # ─── Secretos del sistema ─────────────────────────────────────────────
  # El hash de la contrasena del usuario no se escribe en ningun fichero
  # del repo en claro: vive cifrado (sops + age) en
  # secrets/system-secrets.yaml y el modulo sops-nix lo descifra en
  # activacion, ANTES de crear los usuarios (neededForUsers), dejandolo
  # en /run/secrets-for-users/user_password_hash (root, 0400).
  #
  # La clave age vive en ~/.config/sops/age/keys.txt, FUERA del repo.
  sops = {
    age.keyFile = "/home/pozito/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/system-secrets.yaml;

    secrets."user_password_hash" = {
      key = "user_password_hash";
      # Descifrar ANTES de crear usuarios: lo exige el hash de contrasena.
      neededForUsers = true;
      mode = "0400";
    };
  };

  # Escritura en dispositivos extraibles (SD, USB)
  services.udev.extraRules = ''
    SUBSYSTEM=="block", ATTR{removable}=="1", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 0660 /dev/%k"
    SUBSYSTEM=="block", ATTR{removable}=="1", ACTION=="change", RUN+="${pkgs.bash}/bin/bash -c 'echo 0 > /sys/block/%k/ro'"
  '';

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-33.4.11"
      "electron-39.8.10"
    ];
    packageOverrides = pkgs: {
      openldap = pkgs.openldap.overrideAttrs (old: {
        doCheck = false;
      });
    };
  };

  environment.variables = {
    JAVA_HOME = "${pkgs.jdk17}";
    ANDROID_HOME = "$HOME/Android/Sdk";
    ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
  };

  system.stateVersion = "26.11";
}

#sudo nixos-rebuild switch --impure --flake '/home/pozito/nixos#pozito-desktop'
#sudo nix-collect-garbage -d
#sudo nix-env -p /nix/var/nix/profiles/system --delete-generations




#la key de oracle hay alguna manera de tenerla donde lo tenia? tengo el repo privado vaya. Lo de los templates para que es? 

#tammbien habria que mirar para subir los dotfiles... para replicar el sistema 1:1
