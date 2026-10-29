{
  description = "Homelab NixOS Flake";
  

  inputs = {
    # Nixpkgs and Home Manager
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional Inputs
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # Secretos cifrados con sops (age). El modulo de home-manager los
    # descifra en runtime, asi que las claves privadas nunca llegan al
    # nix store ni al repositorio.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland and Plugins
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Themes
     stylix = {
      url = "github:nix-community/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, hyprland, hyprland-plugins, stylix, sops-nix, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.pozito-desktop = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # Core NixOS modules
          ./hardware-configuration.nix
          ./disko-config.nix
          ./configuration.nix

          # Themes
          stylix.nixosModules.stylix

          # Disko and Home Manager integration
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager

          # Secretos cifrados con sops a nivel de SISTEMA. Necesario para
          # el hash de la contrasena del usuario: se descifra en activacion
          # (antes de crear los usuarios) y nunca vive en claro en el repo.
          sops-nix.nixosModules.sops
          
          # Home Manager user configuration
          {
            home-manager.users.pozito = import ./home.nix;
            home-manager.backupFileExtension = "back";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Modulo de sops para Home Manager: los secretos se descifran en
            # runtime (servicio de usuario sops-nix), no en tiempo de build.
            home-manager.sharedModules = [
              sops-nix.homeManagerModules.sops
              {
                sops.package = sops-nix.packages.${system}.sops-install-secrets;
              }
            ];

            nixpkgs.overlays = [];
          }
        ];

        # Pass inputs to Home Manager and Disko modules if needed
        specialArgs = {
          meta = { hostname = "pozito-desktop"; };
          inherit inputs;
        };
      };
    };
}
