# Paquete de wayle parcheado.
#
# Se parchea por dos motivos:
#
# 1. El fix de sqlite (upstream nixpkgs 41ae85827bcd, "wayle: use
#    system sqlite"), que todavia no esta en el nixpkgs fijado.
#
#    Sin `sqlite` en buildInputs, el crate `wayle-notification`
#    (publicado en crates.io, fuera del workspace de wayle) depende de
#    `rusqlite` SIN la feature `bundled`, de modo que `libsqlite3-sys`
#    busca sqlite3 en el sistema y el link falla con:
#      ld.bfd: cannot find -lsqlite3: No such file or directory
#
# 2. El viewBox que les falta a sus SVG.
#
#    Los SVG que trae wayle (los de Lucide "ld-*" y los de Simple Icons
#    "si-*", entre otros) declaran width/height fijos y SIN viewBox:
#
#      <svg width='16' height='16' xmlns:gpa='...'>
#
#    GTK4 necesita el viewBox para escalar un SVG. Sin el, rasteriza el
#    dibujo a 16x16 y lo ESTIRA al tamano que le pida el layout, con lo
#    que los iconos salen deformados: el logo de NixOS del boton de
#    dashboard se veia como una raya vertical, y el altavoz y el bluetooth
#    como flechas.
#
#    El parche es minimo: solo cambia la cabecera del <svg>, sin tocar
#    el path.
#
# POR QUE NO ES UN OVERLAY:
#
# Un `nixpkgs.overlays` dentro de un modulo NixOS se aplica al pkgs
# global, y ese mismo pkgs es el `prev` del overlay: recursion
# infinita. Y como home-manager usa `useGlobalPkgs = true` (el mismo
# pkgs que el sistema), duplicar el overlay en la parte de home-manager
# tampoco funciona.
#
# Ademas, el modulo services.wayle de home-manager usa SU propio
# pkgs.wayle (no el del sistema), asi que hay que pasarle el paquete
# parcheado explicitamente con services.wayle.package.
#
# Cuando el pin de nixpkgs suba a un commit que incluya el parche de
# sqlite, la parte (1) se puede borrar sin mas. La parte (2) depende
# de que upstream anada el viewBox a sus SVG.
{ pkgs }:

pkgs.wayle.overrideAttrs (old: {
  # Fix (1): sqlite del sistema.
  buildInputs = old.buildInputs ++ [ pkgs.sqlite ];

  postInstall = (old.postInstall or "") + ''
    # Fix (2): iconos con viewBox.
    for f in $(find $out/share/icons -name "*.svg" 2>/dev/null); do
      if ! grep -q "viewBox" "$f"; then
        w=$(sed -n "s/.*width=['\"]\{0,1\}\([0-9.]*\).*/\1/p" "$f" | head -1)
        h=$(sed -n "s/.*height=['\"]\{0,1\}\([0-9.]*\).*/\1/p" "$f" | head -1)
        if [ -n "$w" ] && [ -n "$h" ]; then
          # OJO: el <svg va seguido de "width=", no de un espacio.
          sed -i "s|<svg width=|<svg viewBox=\"0 0 $w $h\" width=|" "$f"
        fi
      fi
    done
  '';
})
