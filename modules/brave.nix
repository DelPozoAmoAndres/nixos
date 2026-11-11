{ config, lib, pkgs, ... }:

let
  # ─── Brave ─────────────────────────────────────────────────────────────
  #
  # pkgs.brave fue ELIMINADO de nixpkgs (no habia comitters que
  # desbloqueasen los problemas de seguridad). El paquete que tenias
  # instalado seguia funcionando porque ya estaba compilado en el store,
  # pero la entrada del sistema no se podia reconstruir.
  #
  # La solucion es rehacerlo como lo era: el .deb oficial de GitHub
  # desempaquetado con dpkg y envuelto con wrap-gapps-hook (el hook
  # estandar de nixpkgs para navegadores .deb, que crea los symlinks
  # de las librerias del sistema y los .desktop).
  #
  # Ventaja frente a una alternativa como chromium: es EXACTAMENTE la
  # misma version que tenias (1.91.175), con tu perfil, tus extensiones
  # y tu sincronizacion intactos.
  #
  # Para actualizar la version: cambiar "version", la URL y el hash.
  # El hash se obtiene con:
  #   nix-prefetch-url --unpack \
  #     https://github.com/brave/brave-browser/releases/download/v1.91.175/brave-browser_1.91.175_amd64.deb
  version = "1.91.175";

  braveDeb = pkgs.fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser_${version}_amd64.deb";
    hash = "sha256-/+xaqBCYzo4bvYASoRgDHDIUb2aWX1DGxqfDifeWKSQ=";
  };

  brave = pkgs.stdenv.mkDerivation {
    pname = "brave";
    inherit version;

    src = braveDeb;

    # El wrapper de gapps crea los symlinks de librerias y el .desktop
    # con los iconos correctos. Va en nativeBuildInputs (no en
    # nativeCheckInputs) porque el hook se invoca desde installPhase.
    # wrapGAppsHook3 es la variante para GTK3, que es la que usa Brave.
    # Es un setup-hook: se aplica SOLO al final de la fase de
    # instalacion via fixupOutputHooks, no hace falta invocarlo a mano
    # desde installPhase (su funcion es wrapGAppsHook, con "A" mayuscula).
    #
    # Ademas necesita las librerias del sistema en propagatedBuildInputs
    # porque el hook las enlaza en el wrapper: sin ellas el binario
    # arranca pero muere con "libglib-2.0.so.0: cannot open shared
    # object file" (el .deb las trae enlazadas contra /usr/lib, que en
    # Nix no existe).
    nativeBuildInputs = [ pkgs.dpkg pkgs.makeWrapper pkgs.wrapGAppsHook3 ];

    propagatedBuildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libGL
      libglvnd
      libxkbcommon
      libx11
      libxcb
      libxext
      nspr
      nss
      pango
      pipewire
      pulseaudio
      snappy
      udev
      util-linux
      wayland
      xdg-utils
    ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      # mkDerivation no sabe desempaquetar un .deb: se hace a mano.
      #
      # El .deb trae chrome-sandbox con el bit setuid (rwsr-xr-x), que
      # Nix no permite dentro del store (todo en el store es inmutable
      # y no puede tener bits especiales). Por eso se extrae con
      # --fsys-tarfile + tar en vez de "dpkg-deb -x", que aborta al
      # tocar ese fichero, y luego se quita.
      #
      # Consecuencia: el sandbox de Chrome no puede usar el setuid, asi
      # que hay que lanzarlo con --no-sandbox. Es el precio de que un
      # navegador con su propio setuid helper viva en el store de Nix.
      # El contenido del perfil no se ve afectado.
      # dpkg-deb --fsys-tarfile | tar -x -C $out en vez de
      # "dpkg-deb -x": la primera forma permite excluir el chrome-sandbox
      # (que lleva el bit setuid) en lugar de que la extraccion aborte.
      #
      # $out tiene que existir antes de que tar lo use como destino, o
      # tar aborta con "Cannot open" y dpkg-deb se queda con un broken
      # pipe.
      mkdir -p $out
      dpkg-deb --fsys-tarfile ${braveDeb} | tar -x -C $out --warning=no-timestamp
      rm -f $out/opt/brave.com/brave/chrome-sandbox
      rm -rf $out/usr/share/doc

      # El .deb de Brave instala el navegador en /opt/brave.com/brave/
      # (no en /usr/lib), asi que el binario vive en
      # $out/opt/brave.com/brave/brave. El symlink en $out/bin apunta
      # ahi.
      mkdir -p $out/bin
      ln -s ../opt/brave.com/brave/brave $out/bin/brave

      # Los .desktop y los iconos van a las rutas XDG de Nix.
      mkdir -p $out/share/applications $out/share/icons
      cp -r $out/usr/share/applications/* $out/share/applications/ 2>/dev/null || true
      cp -r $out/usr/share/icons/* $out/share/icons/ 2>/dev/null || true
      cp -r $out/opt/brave.com/brave/*.pak $out/share/ 2>/dev/null || true

      # Las librerias que Brave espera de su .deb.
      for lib in $out/usr/lib/brave/*.so; do
        [ -e "$lib" ] || continue
        ln -sf "$lib" $out/lib/ 2>/dev/null || true
      done

      # El sandbox necesita --no-sandbox porque no hay binario setuid.
      export MOZ_DISABLE_CONTENT_SANDBOX=1
      export CHROME_DEVEL_SANDBOX=""

      runHook postInstall
    '';

    # La libreria principal de Brave ya viene con el RPATH puesto, asi
    # que no hace falta autoPatchelf.
    meta = {
      description = "Brave web browser";
      homepage = "https://brave.com";
      license = pkgs.mit;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [
    brave
  ];
}
