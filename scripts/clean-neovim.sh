#!/usr/bin/env bash
# Limpia los restos de las configuraciones anteriores de Neovim para que
# Home Manager pueda desplegar sus symlinks sin conflictos.
#
# La configuracion actual (modules/neovim.nix) no necesita nada de esto:
# todo sale del nix store. Este script solo sirve para migrar desde una
# instalacion de LazyVim "normal" (con lazy.nvim descargando plugins) o
# desde la version anterior de este modulo.
set -uo pipefail

echo "== Limpiando restos de la config anterior =="

# Plugins descargados por lazy.nvim en runtime (ya no se usan: todo viene
# del nix store).
if [ -d ~/.local/share/nvim/lazy ]; then
  echo "  rm -rf ~/.local/share/nvim/lazy"
  rm -rf ~/.local/share/nvim/lazy
fi

# Cache de lazy.nvim.
if [ -d ~/.cache/nvim/lazy ]; then
  echo "  rm -rf ~/.cache/nvim/lazy"
  rm -rf ~/.cache/nvim/lazy
fi

# Lockfile y estado de extras generados por lazy.nvim (ya no se usan).
for f in ~/.config/nvim/lazy-lock.json ~/.config/nvim/lazyvim.json; do
  if [ -f "$f" ]; then
    echo "  rm -f $f"
    rm -f "$f"
  fi
done

# Directorios REALES que bloquean la creacion de los symlinks que Home
# Manager quiere poner en su sitio (site/parser, site/queries).
for d in ~/.local/share/nvim/site/parser ~/.local/share/nvim/site/queries; do
  if [ -e "$d" ] && [ ! -L "$d" ]; then
    echo "  rm -rf $d  (directorio real que bloquea el symlink)"
    rm -rf "$d"
  fi
done

# Backups que dejo Home Manager al cambiar un directorio por un symlink.
for d in ~/.local/share/nvim/site/parser.back ~/.local/share/nvim/site/queries.back; do
  if [ -d "$d" ]; then
    echo "  rm -rf $d  (backup obsoleto)"
    rm -rf "$d"
  fi
done

# Estado viejo de lazy.nvim.
if [ -d ~/.local/state/nvim/lazy ]; then
  echo "  rm -rf ~/.local/state/nvim/lazy"
  rm -rf ~/.local/state/nvim/lazy
fi

# `site/queries` lo crea nvim-treesitter vacio al inicializar (su
# `get_install_dir` hace mkdir). Es inocuo: las queries reales se
# resuelven por runtimepath desde el propio plugin. Se borra para no
# ensuciar, pero volvera a aparecer.
if [ -d ~/.local/share/nvim/site/queries ] && [ -z "$(ls -A ~/.local/share/nvim/site/queries 2>/dev/null)" ]; then
  echo "  rm -rf ~/.local/share/nvim/site/queries  (vacio, lo recrea nvim-treesitter)"
  rm -rf ~/.local/share/nvim/site/queries
fi

# `lazyvim.json` lo escribe el propio plugin LazyVim para recordar los
# extras elegidos. En esta configuracion los extras los define Nix, asi
# que el fichero no se usa; se puede borrar sin riesgo.
if [ -f ~/.config/nvim/lazyvim.json ]; then
  echo "  rm -f ~/.config/nvim/lazyvim.json  (estado de extras, lo define Nix)"
  rm -f ~/.config/nvim/lazyvim.json
fi

echo
echo "== Estado actual de ~/.local/share/nvim/site =="
ls -la ~/.local/share/nvim/site/ 2>/dev/null || echo "  (aun no existe)"
