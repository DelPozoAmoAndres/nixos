{pkgs, inputs, ...}: {
  
  stylix.enable = true;
  stylix.image = /home/pozito/.config/hypr/wallpaperflare.com_wallpaper.jpg;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.fonts = {
    sizes = {
      terminal = 12;
      applications = 12;
      desktop = 10;
      popups = 10;
    };
    monospace = {
      package = pkgs.nerdfonts.override {fonts = ["FiraCode"];};
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
}