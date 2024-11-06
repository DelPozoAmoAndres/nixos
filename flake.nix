{
  description = "Homelab NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    ...
  } @ inputs: let
    nodes = [
      "pozito-desktop"
    ];
  in {
    nixosConfigurations = builtins.listToAttrs (map (name: {
        name = name;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {
            meta = {hostname = name;};
          };
          system = "x86_64-linux";
          modules = [
            # Modules
            disko.nixosModules.disko
            ./hardware-configuration.nix
            ./disko-config.nix
            ./configuration.nix
          ];
        };
      })
      nodes);
  };
}