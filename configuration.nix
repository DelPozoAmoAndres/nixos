{ config, lib, user, pkgs, meta, ... }:

{

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

  };

  # Enable GNOME desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
  };

  # enable docker
  virtualisation.docker.enable = true;

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    git
    curl
    tmux
    heroic
    lutris
    vesktop
    bitwarden
    brave
    goverlay
    mangohud
    protonup
    bottles

    # https://github.com/Ulauncher/Ulauncher/wiki/Hotkey-In-Wayland
    ulauncher 
    wmctrl

    # Vscode and extensions
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        enkia.tokyo-night
      ];
    })
  ];

  # allow unfree
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.allowUnfreePredicate = pkg : builtins.elem (lib.getName pkg)[
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
  ];

  programs = {
    gamemode.enable = true;
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  system.stateVersion = "23.11";

}
