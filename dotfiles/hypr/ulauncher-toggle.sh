#!/usr/bin/env bash
#
# Muestra u oculta la ventana de ulauncher.
#
# POR QUE NO SE USA EL TOGGLE POR D-BUS:
#
# Ulauncher 5.15.7 sobre Wayland tiene el toggle_window roto: si la
# ventana esta oculta (o no existe todavia), el toggle no la muestra. La
# ventana queda "mapped" pero invisible y el siguiente toggle tampoco
# la muestra. Solo relanzar el proceso la muestra de forma fiable.
#
# Ademas, el shim "ulauncher-toggle" del paquete acaba haciendo un
# "wmctrl -a" (X11) que en Wayland no funciona, y su salida es un error
# ("Cannot get client list properties") con codigo 1.
#
# QUE SE HACE:
#
#   - Si la ventana esta en primer plano (focusHistoryID == 0) se mata
#     el proceso: se oculta.
#   - Si no esta, se relanza ulauncher: aparece con su ventana.
#
# Para detectar si esta visible se usa focusHistoryID == 0. NO sirven los
# campos mapped/visible de hyprctl (en Wayland la ventana sigue
# existiendo con mapped=true aunque este oculta) ni el tamano (606x76
# tanto visible como oculta).

set -u

destino="net.launchpad.ulauncher"
ruta="/net/launchpad/ulauncher"
metodo="net.launchpad.ulauncher.toggle_window"

# La ventana esta en primer plano?
visible() {
    hyprctl clients -j 2>/dev/null | python3 -c "
import json, subprocess, sys
try:
    clients = json.loads(subprocess.run(
        ['hyprctl', 'clients', '-j'], capture_output=True, text=True).stdout or '[]')
except Exception:
    clients = []
for c in clients:
    if c.get('class') == 'ulauncher' and c.get('focusHistoryID') == 0:
        sys.exit(0)
sys.exit(1)
" && echo sí || echo no
}

if [ "$(visible)" = "sí" ]; then
    # Esta abierta: se mata el proceso para ocultarla.
    pkill -x ulauncher 2>/dev/null || true
    pkill -x .ulauncher-wrap 2>/dev/null || true
    exit 0
fi

# No esta abierta: se relanza. Ulauncher muestra su ventana al arrancar
# (sin --hide-window, que la deja en un estado del que no se puede
# salir).
pkill -x ulauncher 2>/dev/null || true
pkill -x .ulauncher-wrap 2>/dev/null || true
sleep 0.3

ulauncher --no-window-shadow >/dev/null 2>&1 &

# Se espera a que la ventana aparezca y se registre en D-Bus.
for _ in $(seq 1 24); do
    sleep 0.25
    if [ "$(visible)" = "sí" ]; then
        break
    fi
done

exit 0
