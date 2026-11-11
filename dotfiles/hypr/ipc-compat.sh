#!/usr/bin/env bash
# Hyprland 0.55 movio el socket IPC a <instancia>/.socket.sock y
# <instancia>/.socket2.sock. Las librerias de barra (waybar, etc)
# siguen buscando <instancia>/socket y <instancia>/socket2, asi que sin
# estos enlaces no se conectan y los botones de la barra dejan de responder.
#
# Hyprland 0.55 tiene dos modos de config:
#   - Lua (hyprland.lua): los dispatchers clasicos dejan de existir, asi que
#     el panel no puede cambiar de workspace.
#   - Legacy (hyprland.conf): sigue soportado y mantiene los dispatchers.
# Con el modo legacy este script es lo que hace funcionar los clics.
#
# IMPORTANTE: este script se lanza al arrancar Hyprland, en el mismo
# instante en que el compositor esta creando sus sockets. Si se ejecuta
# una sola vez, es muy probable que todavia no existan y los enlaces no
# se creen nunca: los botones de la barra se quedan sin responder.
#
# Por eso se reintenta durante unos segundos, en segundo plano.

set -u

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

enlazar() {
    local cambios=0
    for dir in "$runtime"/hypr/*/; do
        [ -S "$dir/.socket.sock" ] && ln -sf .socket.sock "$dir/socket" && cambios=1
        [ -S "$dir/.socket2.sock" ] && ln -sf .socket2.sock "$dir/socket2" && cambios=1
    done
    return $cambios
}

# Primer intento: por si los sockets ya estan.
enlazar || {
    # Reintentos: Hyprland crea los sockets shortly despues de arrancar.
    for _ in $(seq 1 30); do
        sleep 0.5
        if enlazar; then
            exit 0
        fi
    done
    exit 0
}
