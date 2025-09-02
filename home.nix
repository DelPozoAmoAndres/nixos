{ config, inputs, lib, pkgs, ... }: {
  
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
 
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "pozito";
  home.homeDirectory = "/home/pozito";
  home.stateVersion = "24.05"; # Please read the comment before changing.
 
  # Git
  programs.git = {
    enable = true;
    userName = "Andrés"; 
    userEmail = "asdfandres09@gmail.com";
  };

  # Kitty
  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };

  # Rofi
  programs.rofi.enable = true;

  services.udiskie = {
    enable = true;
    settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = {
            # replace with your favorite file manager
            file_manager = "${pkgs.nemo-with-extensions}/bin/nemo";
        };
    };
};
 
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
 
  home.file = {
  };

  home.sessionVariables = {
    XDG_DATA_DIRS = "${pkgs.glib}/share:/var/lib/flatpak/exports/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share";
  };

 
}