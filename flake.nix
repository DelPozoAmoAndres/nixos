{
  description = "Homelab NixOS Flake";

  inputs = {
    # Nixpkgs and Home Manager
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional Inputs
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    
    # Hyprland and Plugins
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Themes
    stylix.url = "github:danth/stylix";
  };

  outputs = { self, nixpkgs, home-manager, disko, hyprland, hyprland-plugins, ... } @ inputs:
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
          inputs.stylix.nixosModules.stylix

          # Disko and Home Manager integration
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          
          # Home Manager user configuration
          {
            home-manager.users.pozito = import ./home.nix;
            home-manager.backupFileExtension = "back";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
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
