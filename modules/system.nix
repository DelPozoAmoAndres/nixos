{ config, lib, pkgs, ... }:

{
  # ─── Nix ───────────────────────────────────────────────────────────────
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      # 2 jobs con 2 hilos: 4 de los 8 hilos quedan libres para VMs, agentes
      # y el escritorio. Con 4 jobs un build saturaba la QVO y bloqueaba
      # dmcrypt, congelando todo el sistema.
      max-jobs = 2;
      cores = 2;
      # auto-optimise-store recorre el store entero (74 GB) hardlinkando
      # ficheros identicos: en esta QVO sin DRAM dispara una tormenta de I/O
      # de varios minutos en cada arranque. Si quieres dedupear, ejecuta
      # "nix store optimise" a mano cuando te venga bien.
      auto-optimise-store = false;
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ stdenv.cc.cc.lib zlib curl openssl ];
  };

  # ─── Arranque ──────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 200;
    };
    efi.canTouchEfiVariables = false;
  };

  # ─── Seguridad ─────────────────────────────────────────────────────────
  security = {
    sudo.extraRules = [
      {
        users = [ "pozito" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    polkit.enable = true;
    rtkit.enable = true;
  };

  # ─── Usuarios ──────────────────────────────────────────────────────────
  users.users.pozito = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "plugdev" "adbusers" "gamemode" "vboxusers" "kvm" ];
    # La contrasena NO esta en el repo: el hash se descifra en activacion
    # desde secrets/system-secrets.yaml (sops + age). Ver "Secretos del
    # sistema" en configuration.nix.
    hashedPasswordFile = "/run/secrets-for-users/user_password_hash";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2PZ42g+dR8d/Qroi9ShxEvrvv5hEuTQaiqmcBrpT0O2TsMulIf6KAAID4gDEE7uzjPp/yu5SvNpoMYZEbM/SDnnGDE3c1OmfvvuWtkl/sDiT5laXsYlm58S5tXf48gxmIeXiXx0SD/ZuNjQCBzwjjLVqOdyl0vniw05u1J2kv4dy3Dk1bcs0VlxG09FyNQjogE7rE2MsbzQVf1+jMUjyFe24nRK2xn4JPGlfP7q6wXcTrYAolYzmAWh1bnnLlA8xGY8bk3QVMgmUAtajyYbwYaAxI1lBPUkFmz7T5re9BeBsPlKa/rGp7UJokIfs1NYKfsI2ekWRhpIrO7Clv/+s4xGEqO2pnVo658ut8243sAWa8WsVVHNB0Eem49+XWaxvOndjTBkz7wNMEf+L76h7rePRHnti1J3liROkJJP4k7T4ls44lK8acLRwbSGnaxk4189Ivh7LakbjZrZuFqP7tcXqVVTBimYvymcZSq9K9Ivi3cFe91ZamjZdNTjtUjo9TJlMc/+WMcrjVOMymCsQBzzoHLuRg/A4ePKud+BpcHZF1w8XRoy583JrWiy+t3XTGUX56mScpvoXn/VAnx+nVb0ifbZQ7mY8P7apuxhDcu/aNQdDmmkWvno6xh6ufc5P8U/BlY+QpUkZ2K5v69pyAV8/lJbTKFNt/WKTNERsdyQ== alexnavia3@MacBook-Air.local"
    ];
  };

  # ─── Red ───────────────────────────────────────────────────────────────
  # El tema de cursor lo lee el compositor al arrancar: se fija aqui para que
  # llegue al proceso de Hyprland aunque el config se cargue mas tarde.
  environment.etc."environment".text = ''
    HYPRCURSOR_THEME=Adwaita
    XCURSOR_THEME=Adwaita
  '';

  # GC automatico semanal: el store llega a 74 GB y la QVO va justa. Borra
  # rutas huerfanas (builds cancelados, derivaciones viejas) y generations
  # de mas de 14 dias.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Limita la cache de fontconfig: con 74 GB de store, la del home llegaba a
  # 130 MB con 26.000 entradas de store paths ya borrados.
  # OJO: esto va en el conf.d del usuario (home.nix), no en /etc: /etc/fonts
  # es un symlink de solo lectura al paquete de fontconfig y meter un
  # fichero dentro rompe la derivacion "etc".

  # El journal se queda en 4 GB por defecto (10% del filesystem). Son logs
  # viejos, no historico util.
  environment.etc."systemd/journald.conf.d/10-size.conf".text = ''
    [Journal]
    SystemMaxUse=200M
    SystemKeepFree=1G
  '';

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  time.timeZone = "Europe/Madrid";

  # ─── Sesión gráfica y servicios de usuario ────────────────────────────
  services.getty = {
    autologinUser = "pozito";
  };

  programs.bash.loginShellInit = ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
      sleep 1
      exec start-hyprland
    fi
  '';

  # El gestor de servicios de usuario arrancaba al boot para el cliente
  # de VPN; hoy Pangolin es un servicio de sistema, pero se deja por si
  # se vuelve a necesitar algun servicio de usuario en el arranque.
  systemd.services."linger@pozito" = {};

  # ─── Pangolin (VPN WireGuard) ──────────────────────────────────────────
  # Cliente de Pangolin/NetBird. Servicio de SISTEMA (root) y en primer
  # plano (--attach), por dos motivos:
  #
  #  - root: crear la interfaz WireGuard y tocar /etc/resolv.conf exige
  #    privilegios. Como servicio de usuario fallaba con
  #    "elevated permissions are required for network interface creation".
  #  - --attach: el proceso no se demoniza, systemd lo vigila de verdad y
  #    al parar le manda SIGTERM, momento en el que el cliente restaura el
  #    DNS original. En modo detached systemd lo mataba al salir el
  #    proceso padre (KillMode=control-group) y entraba en un bucle de
  #    reinicios que saturaba el journal.
  #
  # Las credenciales NO estan en el repo: el cliente las lee de
  # ~/.config/pangolin/accounts.json (fuera del repo). Por eso el servicio
  # fija HOME=/home/pozito y NO lleva --endpoint ni --secret (asi el
  # endpoint interno no se publica en el repositorio).
  systemd.services.pangolin = {
    description = "Pangolin VPN Client (WireGuard + DNS)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # Corta el bucle de reinicios (llego a 201 intentos) si el servidor no
    # responde: como mucho 5 arranques en 5 minutos.
    startLimitIntervalSec = 300;
    startLimitBurst = 5;
    serviceConfig = {
      ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up --attach";
      Environment = "HOME=/home/pozito";
      Restart = "on-failure";
      RestartSec = 30;
      # Margen para el cierre limpio (restaurar DNS, quitar la interfaz).
      TimeoutStopSec = 30;
    };
    wantedBy = [ "multi-user.target" ];
  };

  # ─── Utilidades basicas ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    wget
    # Cliente de la VPN (tambien lo usa el servicio pangolin).
    pangolin-cli
  ];

  # ─── Sistema de ficheros y servicios ───────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /run/polkit-1/rules.d 0755 root root -"
    "d /usr/local/share/polkit-1/rules.d 0755 root root -"
    "d /var/lib/systemd/linger 0755 root root -"
  ];
}
