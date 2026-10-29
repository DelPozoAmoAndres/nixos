{ config, lib, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ─── Tema ──────────────────────────────────────────────────────────────
  stylix = {
    enable = true;
    targets = {
      gnome.enable = false;
      console.enable = false;
    };
    base16Scheme = {
      yaml = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      use-ifd = "auto";
    };
    # Por defecto esto viene a false/null, asi que el tema de iconos y el de
    # cursor nunca se aplicaban: GTK se quedaba sin gtk-icon-theme-name y
    # dibujaba cuadrados, y el cursor seguia siendo el por defecto.
    icons = {
      enable = true;
      package = pkgs.adwaita-icon-theme;
      light = "Adwaita";
      dark = "Adwaita";
    };
    cursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
    fonts = {
      sizes = {
        terminal = 12;
        applications = 12;
        desktop = 10;
        popups = 10;
      };
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };

  fonts.packages = with pkgs; [
    font-awesome
    material-design-icons
    material-symbols
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    papirus-icon-theme
    adwaita-icon-theme
  ];

  # ─── Aplicaciones y utilidades de Hyprland ─────────────────────────────
  # adwaita-icon-theme va tambien en systemPackages para que su share/icons
  # entre en el path del sistema: sin esto el tema de cursor Adwaita no se
  # encuentra y el cursor sale por defecto.
  # Sin GSETTINGS_SCHEMA_DIR las apps GTK no encuentran sus schemas y
  # dibujan cuadrados en lugar de iconos: el perfil del sistema no lleva
  # share/glib-2.0/schemas.
  environment.sessionVariables.GSETTINGS_SCHEMA_DIR =
    let p = pkgs.gsettings-desktop-schemas;
    in "${p}/share/gsettings-schemas/${p.name}/glib-2.0/schemas";

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    # Sin esto el perfil del sistema no tiene share/glib-2.0/schemas y GTK
    # dibuja cuadrados en vez de iconos (Nautilus,菜单, emblemas).
    gsettings-desktop-schemas
    # Agente de autorizacion: sin el, montar discos o hacer cambios de
    # polkit no pide permisos y falla en silencio.
    hyprpolkitagent
    ulauncher
    nautilus
    pavucontrol
    kitty
    hyprpaper
    hyprlock
    hyprshot
    playerctl
    hyprpanel
    (pkgs.writeShellScriptBin "hyprexit" ''
      ${pkgs.hyprland}/bin/hyprctl dispatch exit
      ${pkgs.systemd}/bin/loginctl terminate-user "pozito"
    '')
    brave
    vesktop
    pear-desktop
    telegram-desktop
    bitwarden-desktop
    notesnook
    filezilla
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
