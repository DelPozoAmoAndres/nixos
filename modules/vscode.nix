{ pkgs, ... }: {

    environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
        vscode = vscode;
        vscodeExtensions = with vscode-extensions; [
            catppuccin.catppuccin-vsc
            github.copilot
            github.copilot-chat
            ms-vscode-remote.remote-ssh
            vscode-extensions.ritwickdey.liveserver
            ms-vscode.live-server
            vscode-extensions.ms-vscode-remote.remote-containers
            astro-build.astro-vscode
            ms-vsliveshare.vsliveshare
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
                name = "es7-react-js-snippets";
                publisher = "dsznajder";
                version = "4.4.3";
                sha256 = "sha256-QF950JhvVIathAygva3wwUOzBLjBm7HE3Sgcp7f20Pc=";
            }
            {
                name= "vscode-tailwindcss";
                publisher = "bradlc";
                version = "0.12.6";
                sha256 = "sha256-lnWYw0eRpqYI6U1m6NMQD6Y7+Ae31zcy4CM+o5lB8DA=";
            }

        ];
    })
    ];
}