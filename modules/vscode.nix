{ pkgs, ... }: {

    environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
        vscode = vscode;
        vscodeExtensions = with vscode-extensions; [
            catppuccin.catppuccin-vsc
            github.copilot
            github.copilot-chat
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
                name = "es7-react-js-snippets";
                publisher = "dsznajder";
                version = "4.4.3";
                sha256 = "sha256-QF950JhvVIathAygva3wwUOzBLjBm7HE3Sgcp7f20Pc=";
            }
            {
                name = "ionic";
                publisher = "ionic";
                version = "1.98.0";
                sha256 = "sha256-RROXuext9ouJmkcrDsV0N18DfyiON+snoaiVEJz9ldQ=";
            }
        ];
    })
    ];
}