{ config, lib, pkgs, inputs, ... }:

let
  # Wayle parcheado (fix de sqlite + viewBox de los iconos).
  # Ver modules/wayle-patched.nix para el detalle.
  waylePatched = import ./wayle-patched.nix { inherit pkgs; };
in
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ─── Agente de autorizacion de polkit ───────────────────────────────────
  #
  # El paquete hyprpolkitagent trae el ejecutable en libexec/ y un
  # servicio de systemd de usuario (hyprpolkitagent.service). El
  # servicio es la forma correcta de lanzarlo: el binario no esta en
  # $PATH (esta en libexec/), asi que lanzarlo a mano desde el autostart
  # de Hyprland no funciona.
  #
  # Sin el, montar discos o pedir permisos de polkit falla en silencio.
  systemd.user.services.hyprpolkitagent = {
    description = "Agente de autorizacion de polkit para Hyprland";
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 2;
    };
    wantedBy = [ "graphical-session.target" ];
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
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
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
    ulauncher
    nautilus
    pavucontrol
    kitty
    hyprpaper
    hyprlock
    hyprshot
    playerctl
    # HyprPanel fue ARCHIVADO en nixpkgs (el paquete lanza un error y el
    # sistema no rebuild). El sustituto oficial es Wayle, reescrito en
    # Rust con GTK4: mucho mas ligero (HyprPanel era GTK/JS con un motor
    # web entero debajo) y con modulos NATIVOS de CPU y RAM, que en
    # HyprPanel eran placeholders sin lectura real por nucleo.
    #
    # Se usa la version parcheada (fix de sqlite + viewBox de los
    # iconos), definida mas arriba en este modulo.
    #
    # OJO: dentro de "with pkgs;" el nombre "wayle" resolveria al
    # paquete SIN parchear, asi que el parcheado se llama distinto.
    waylePatched
    (pkgs.writeShellScriptBin "hyprexit" ''
      ${pkgs.hyprland}/bin/hyprctl dispatch exit
      ${pkgs.systemd}/bin/loginctl terminate-user "pozito"
    '')
    vesktop
    pear-desktop
    telegram-desktop
    bitwarden-desktop
    notesnook
    filezilla
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
