#!/usr/bin/env bash
# Hyprland 0.55 movio el socket IPC a <instancia>/.socket.sock y
# <instancia>/.socket2.sock. Las librerias Astal (hyprpanel, waybar, etc)
# siguen buscando <instancia>/socket y <instancia>/socket2, asi que sin
# estos enlaces no se conectan y los botones de la barra dejan de responder.
#
# Hyprland 0.55 tiene dos modos de config:
#   - Lua (hyprland.lua): los dispatchers clasicos dejan de existir, asi que
#     hyprpanel no puede cambiar de workspace.
#   - Legacy (hyprland.conf): sigue soportado y mantiene los dispatchers.
# Con el modo legacy este script es lo que hace funcionar los clics.

set -u

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

for dir in "$runtime"/hypr/*/; do
  [ -S "$dir/.socket.sock" ] && ln -sf .socket.sock "$dir/socket"
  [ -S "$dir/.socket2.sock" ] && ln -sf .socket2.sock "$dir/socket2"
done
