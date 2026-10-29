{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Toolchains
    gcc
    gnumake
    cmake
    ninja
    flex
    bison
    gperf
    ccache
    go
    jdk17
    gradle
    android-studio
    nodejs
    (python3.withPackages (ps: with ps; [ pip setuptools wheel ]))

    # Secretos: sops cifra/descifra, age genera las claves.
    # Uso: sops secrets/secrets.yaml   (editar el secreto cifrado)
    sops
    age

    # Utilidades
    templ
    dbeaver-bin
    freecad
    tradingview
    opencode
    vscode-fhs
    antigravity
  ];
}
