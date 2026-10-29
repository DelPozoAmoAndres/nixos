{ config, inputs, lib, pkgs, ... }:

let
  # Hyprland 0.55 tiene dos modos de config. En modo Lua (hyprland.lua) los
  # dispatchers clasicos dejan de existir, asi que hyprpanel deja de cambiar
  # de workspace al pulsar en el. En modo legacy (hyprland.conf) todo sigue
  # funcionando, por eso False por defecto. Ponlo a true si prefieres el
  # formato nuevo y aceptas que los clics de la barra no cambien de workspace.
  useHyprlandLua = false;
in

{
  programs.home-manager.enable = true;

  home.username = "pozito";
  home.homeDirectory = "/home/pozito";
  home.stateVersion = "25.05";

  # Necesario para que Nautilus encuentre los backends de gvfs (udisks2, MTP...)
  # en sesiones sin GNOME como Hyprland
  home.sessionVariables = {
    GIO_EXTRA_MODULES = "/run/current-system/sw/lib/gio/modules";
    XDG_DATA_DIRS = "${pkgs.glib}/share:/var/lib/flatpak/exports/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share";
  };

  # ─── Git ───────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user = {
      email = "asdfandres09@gmail.com";
      name = "Andrés";
    };
  };

  # ─── SSH ───────────────────────────────────────────────────────────────
  # La clave de Oracle (IdentityFile) llega por sops-nix, ver "Secretos".
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings.oracle = {
      HostName = "80.225.185.131";
      User = "ubuntu";
      IdentityFile = "~/.ssh/id_oracle";
    };
  };

  # ─── Terminal ──────────────────────────────────────────────────────────
  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };

  # ─── Streaming / OBS ───────────────────────────────────────────────────
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };

  # ─── Dispositivos extraibles ───────────────────────────────────────────
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.nemo-with-extensions}/bin/nemo";
      };
    };
  };

  # ─── Fuentes ───────────────────────────────────────────────────────────
  # La cache de fontconfig del home queda con entradas de store paths
  # antiguos en cada rebuild: Pango deja de encontrar las fuentes y GTK4
  # pinta tofu (cuadros) en vez de texto. Se regenera solo cuando el
  # sistema ha cambiado, y en segundo plano.
  # Ojo: en home-manager las unidades de usuario usan el formato de
  # systemd (Unit/Service/Install), no el de nixos (description/
  # wantedBy/serviceConfig).
  systemd.user.services.fontconfig-refresh = {
    Unit.Description = "Refrescar la cache de fontconfig si el sistema ha cambiado";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "fontconfig-refresh" ''
        cache="${config.home.homeDirectory}/.cache/fontconfig"
        if [ ! -d "$cache" ] || [ /run/current-system -nt "$cache" ]; then
          ${pkgs.fontconfig}/bin/fc-cache -r
        fi
      ''}";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # ─── Agentes ───────────────────────────────────────────────────────────
  # Skills de Claude y opencode, agentes custom, kit de Penpot y paperclip.
  # Se copian (no se enlazan) porque los gestores de plugins necesitan
  # escribir en esos directorios para instalar o actualizar skills.
  home.activation.installAgentConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.rsync}/bin:${pkgs.coreutils}/bin:$PATH"
    ${config.home.homeDirectory}/nixos/dotfiles/install-agents.sh \
      || echo "aviso: no se pudo desplegar la configuracion de agentes"
  '';

  # ─── Dotfiles ──────────────────────────────────────────────────────────
  # Configuracion de Hyprland, waybar e hyprpanel versionada en el repo.
  home.file = {
    ".config/hypr/hyprland.conf" = {
      source = ./dotfiles/hypr/hyprland.conf;
    };
    ".config/hypr/colors.conf" = {
      source = ./dotfiles/hypr/colors.conf;
    };
    ".config/hypr/hyprpaper.conf" = {
      source = ./dotfiles/hypr/hyprpaper.conf;
    };
    ".config/hypr/ipc-compat.sh" = {
      source = ./dotfiles/hypr/ipc-compat.sh;
    };
    ".config/hypr/wallpaperflare.com_wallpaper.jpg" = {
      source = ./dotfiles/hypr/wallpaperflare.com_wallpaper.jpg;
    };
    ".config/hypr/hyprland.lua" = lib.mkIf useHyprlandLua {
      source = ./dotfiles/hypr/hyprland.lua;
    };
    ".config/hypr/colors.lua" = lib.mkIf useHyprlandLua {
      source = ./dotfiles/hypr/colors.lua;
    };
    ".config/xdg-desktop-portal/portals.conf" = {
      source = ./dotfiles/xdg-desktop-portal/portals.conf;
    };
    ".config/waybar" = {
      source = ./dotfiles/waybar;
      recursive = true;
    };
    ".config/hyprpanel" = {
      source = ./dotfiles/hyprpanel;
      recursive = true;
    };

    # Limita la cache de fontconfig del usuario: con 74 GB de store, la del
    # home llegaba a 130 MB con 26.000 entradas de store paths ya borrados.
    # Va en el conf.d del usuario porque /etc/fonts es un symlink de solo
    # lectura al paquete de fontconfig (no se puede meter nada ahi).
    ".config/fontconfig/conf.d/99-cache-size.conf".text = ''
      <match target="cache">
        <edit name="max_size" mode="assign">
          <int>8388608</int>
        </edit>
      </match>
    '';

    ".config/filezilla/sitemanager.xml" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <FileZilla3 version="3.67.0" platform="*nix">
          <Servers>
            <Server>
              <Host>80.225.185.131</Host>
              <Port>22</Port>
              <Protocol>1</Protocol>
              <Type>0</Type>
              <User>ubuntu</User>
              <Logontype>5</Logontype>
              <Keyfile>/home/pozito/.ssh/id_oracle</Keyfile>
              <Name>Oracle Server</Name>
              <Comments />
              <LocalDir />
              <RemoteDir />
              <SyncBrowsing>0</SyncBrowsing>
              <DirectoryComparison>0</DirectoryComparison>
            </Server>
          </Servers>
        </FileZilla3>
      '';
    };
  };

  # ─── Secretos ─────────────────────────────────────────────────────────
  # La clave privada del servidor Oracle y el token de Gitea se guardan
  # cifrados en secrets/secrets.yaml (sops + age). El modulo sops-nix de
  # home-manager los descifra en runtime y los deja en
  # $XDG_RUNTIME_DIR/secrets.d, con symlinks en ~/.ssh/id_oracle y
  # ~/.config/gitea/token. Asi el texto plano nunca entra en el
  # nix store (que es legible por cualquiera) ni en el repositorio.
  #
  # La clave age vive en ~/.config/sops/age/keys.txt, FUERA del repo.
  # Sin ella no se puede reconstruir el sistema ni descifrar los secretos.
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/secrets.yaml;

    secrets."id_oracle" = {
      key = "id_oracle";
      # Destino del symlink. El fichero real vive en el directorio de
      # runtime del usuario, con permisos 0400.
      path = "${config.home.homeDirectory}/.ssh/id_oracle";
      mode = "0400";
    };

    # PAT de Gitea (git.asealab.lan, scope write:repository). Se lee con
    #   $(cat ~/.config/gitea/token)
    # NO debe aparecer en ningun fichero del repo, ni en claro ni en docs.
    secrets."gitea_token" = {
      key = "gitea_token";
      path = "${config.home.homeDirectory}/.config/gitea/token";
      mode = "0400";
    };
  };
}
