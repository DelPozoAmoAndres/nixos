#!/usr/bin/env bash
#
# Arranque de ulauncher.
#
# Hay que inicializar la ventana antes de poder alternar con el toggle:
# con --hide-window la ventana NUNCA se crea, y el toggle por D-Bus
# responde con exito pero no muestra nada (no hay nada que mostrar).
#
# Asi que se arranca SIN --hide-window (la ventana se crea), se espera a
# que exista, y luego se oculta con un toggle. El daemon queda vivo con
# la ventana creada, que es el estado en el que el atajo alterna de
# forma instantanea (~45ms).
#
# El toggle se hace con "ulauncher-toggle" (el shim del paquete), que
# ademas saca por consola un error de "wmctrl -a" (X11) que es
# inofensivo.

set -u

destino="net.launchpad.ulauncher"
ruta="/net/launchpad/ulauncher"
metodo="net.launchpad.ulauncher.toggle_window"

# NO se mata el proceso anterior aqui: lo hace el autostart_unique de
# Hyprland, que mata antes de lanzar. Si este script tambien lo hiciera,
# el pkill mataria al recien lanzado.
#
# Si ya hay un daemon vivo, se usa el que hay (el toggle funciona
# igual): solo se lanza uno nuevo si no hay ninguno.
if ! pgrep -x ".ulauncher-wrap" >/dev/null 2>&1; then
    ulauncher --no-window-shadow >/dev/null 2>&1 &
fi

# Se espera a que la ventana exista.
ventana_existe() {
    hyprctl clients -j 2>/dev/null | python3 -c "
import json, subprocess, sys
try:
    clients = json.loads(subprocess.run(
        ['hyprctl', 'clients', '-j'], capture_output=True, text=True).stdout or '[]')
except Exception:
    clients = []
sys.exit(0 if any(c.get('class') == 'ulauncher' for c in clients) else 1)
" >/dev/null 2>&1
}

# La ventana esta en primer plano (visible)?
ventana_visible() {
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
" >/dev/null 2>&1
}

for _ in $(seq 1 40); do
    sleep 0.25
    if ventana_existe; then
        break
    fi
done

# Se espera a que la ventana se asiente antes de ocultarla. Ulauncher
# necesita un momento para terminar de construir la ventana (y su CSS):
# si se hace el toggle demasiado pronto, se aplica sobre una ventana a
# medio construir y no hace nada.
sleep 1.5

# Se oculta con el shim del paquete, que es el que alterna bien: hace el
# toggle por D-Bus, espera, y luego el "wmctrl -a" (que en Wayland no
# funciona pero no molesta).
#
# Con "dbus-send" a pelo el toggle no llega a aplicarse: es asincrono y
# hay que darle margen.
#
# OJO: solo se hace un toggle si la ventana esta VISIBLE. Si ya esta
# oculta (no hay ventana), un toggle la mostraria, que es justo lo
# contrario de lo que se quiere al arrancar.
if ventana_visible; then
    ulauncher-toggle >/dev/null 2>&1
fi

exit 0
