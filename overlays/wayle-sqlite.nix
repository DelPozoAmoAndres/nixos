# Overlay que replica el fix upstream de nixpkgs 41ae85827bcd
# ("wayle: use system sqlite"), que todavia no esta en el nixpkgs fijado
# por flake.lock (f4a03c008967).
#
# Sin `sqlite` en buildInputs, el crate `wayle-notification` (publicado en
# crates.io, fuera del workspace de wayle) depende de `rusqlite` SIN la
# feature `bundled`, de modo que `libsqlite3-sys` busca sqlite3 en el
# sistema y el link falla con:
#   ld.bfd: cannot find -lsqlite3: No such file or directory
#
# Cuando el pin de nixpkgs suba a un commit que incluya ese parche, este
# overlay se puede borrar sin mas.
final: prev: {
  wayle = prev.wayle.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ final.sqlite ];
  });
}
