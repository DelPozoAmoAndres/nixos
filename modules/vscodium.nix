{ pkgs, ... }: {

    # List packages installed in system profile. To search, run:
    # $ nix search vscode
    environment.systemPackages = with pkgs; [
        # Vscode and extensions
        (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = with vscode-extensions; [
                enkia.tokyo-night
                pkief.material-icon-theme
                equinusocio.vsc-material-theme
                equinusocio.vsc-material-theme-icons
            ];
        })
    ];
}
