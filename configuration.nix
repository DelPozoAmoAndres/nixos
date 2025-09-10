{ config, lib, user, pkgs, meta, inputs, ... }:

let
   unstablePkgs = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
    };
  };
in {
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [
    ./modules/regreet.nix
    ./modules/gaming.nix
    ./modules/hyprUtility.nix
    ./modules/nvidia.nix
    ./modules/others.nix
    ./modules/theme.nix
    ./modules/ios.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Virtualisation 
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = ["pozito"];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Enable docker
  virtualisation.docker = {
    enable = true;
    extraOptions = "--config-file=/etc/docker/daemon.json --add-runtime=nvidia=/run/current-system/sw/bin/nvidia-container-runtime";
  };

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pozito = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    # Created using mkpasswd
    hashedPassword = "$6$h1XVVTj4VImjA8HU$3NKRaOISDV4zH9P/aDZWSGZTugZxLwRksjAd1lRaynD1eJFpJiFTAlD/q8KG9lnVatuDXUL4EJyDYBkX8i7mB1";
    # si metes aqui un ssh key no pide contra al conectar por ssh
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2PZ42g+dR8d/Qroi9ShxEvrvv5hEuTQaiqmcBrpT0O2TsMulIf6KAAID4gDEE7uzjPp/yu5SvNpoMYZEbM/SDnnGDE3c1OmfvvuWtkl/sDiT5laXsYlm58S5tXf48gxmIeXiXx0SD/ZuNjQCBzwjjLVqOdyl0vniw05u1J2kv4dy3Dk1bcs0VlxG09FyNQjogE7rE2MsbzQVf1+jMUjyFe24nRK2xn4JPGlfP7q6wXcTrYAolYzmAWh1bnnLlA8xGY8bk3QVMgmUAtajyYbwYaAxI1lBPUkFmz7T5re9BeBsPlKa/rGp7UJokIfs1NYKfsI2ekWRhpIrO7Clv/+s4xGEqO2pnVo658ut8243sAWa8WsVVHNB0Eem49+XWaxvOndjTBkz7wNMEf+L76h7rePRHnti1J3liROkJJP4k7T4ls44lK8acLRwbSGnaxk4189Ivh7LakbjZrZuFqP7tcXqVVTBimYvymcZSq9K9Ivi3cFe91ZamjZdNTjtUjo9TJlMc/+WMcrjVOMymCsQBzzoHLuRg/A4ePKud+BpcHZF1w8XRoy583JrWiy+t3XTGUX56mScpvoXn/VAnx+nVb0ifbZQ7mY8P7apuxhDcu/aNQdDmmkWvno6xh6ufc5P8U/BlY+QpUkZ2K5v69pyAV8/lJbTKFNt/WKTNERsdyQ== alexnavia3@MacBook-Air.local"
    ];
  };

  security.sudo.extraRules = [
    { users = [ "pozito" ];
       commands = [
         { command = "ALL" ;
             options= [ "NOPASSWD" ];
         }
       ];
    }
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    xf86_input_wacom
    docker-compose
    albert

    systemd
    ccache
    cmake
    gnumake
    ncurses 
    flex 
    bison 
    gperf
    gcc
    ninja
    (python3.withPackages (ps: with ps; [ pip setuptools wheel ]))
    
    # quickmenu 
    quickemu
    virt-viewer

    # Añadimos vscode-fhs desde unstablePkgs
    unstablePkgs.vscode-fhs
  ];

  networking.networkmanager.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "24.11";

  nixpkgs.config.permittedInsecurePackages = [
    "electron-33.4.11"
  ];

}

#sudo nixos-rebuild switch --impure --flake '/home/pozito/nixos#pozito-desktop'
#sudo nix-collect-garbage -d
#sudo nix-env -p /nix/var/nix/profiles/system --delete-generations
