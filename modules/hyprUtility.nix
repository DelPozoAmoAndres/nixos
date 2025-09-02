{ pkgs, inputs, ... }:

let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
    };
  };
in {
  # Paquetes del sistema
  environment.systemPackages = with pkgs; [
    ulauncher 
    nautilus
    pulseaudio
    pavucontrol
    kitty
    hyprpaper
    hyprlock
    (pkgs.writeShellScriptBin "hyprexit" ''
      ${pkgs.hyprland}/bin/hyprctl dispatch exit
      ${pkgs.systemd}/bin/loginctl terminate-user "pozito"
    '')
    hyprshot
    sway
    playerctl
  ] ++ [
    # Hyprpanel desde nixpkgs-unstable
    unstablePkgs.hyprpanel
  ];

  programs = {
    hyprland = {    
      enable = true;    
      xwayland.enable = true;
    };
  };
}
