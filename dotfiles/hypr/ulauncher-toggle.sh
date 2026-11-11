#!/usr/bin/env bash
#
# Muestra u oculta la ventana de ulauncher.
#
# POR QUE NO SE USA EL TOGGLE POR D-BUS:
#
# Ulauncher 5.15.7 en Wayland tiene el toggle_window roto: la ventana
# queda "mapped" pero invisible, y el siguiente toggle tampoco la
# muestra. Ademas, el shim "ulauncher-toggle" del paquete acaba
# haciendo un "wmctrl -a" (X11) que en Wayland no funciona, y su salida
# es un error ("Cannot get client list properties") con codigo 1.
#
# QUE SE HACE EN SU LUGAR:
#
# Ulauncher se relanza en cada pulsacion. Una instancia nueva muestra
# su ventana al arrancar (es el unico estado en el que se ve de forma
# fiable). Para ocultarla, se cierra con el atajo de escape o se mata
# el proceso: si la ventana esta abierta se mata; si no, se abre.
#
# La deteccion de "esta abierta" no puede usar los campos mapped/
# visible de hyprctl: en Wayland la ventana sigue existiendo aunque
# ulauncher la oculte. Se usa el titulo de la capa, que ulauncher
# cambia a "Ulauncher - Application Launcher" solo cuando la ventana
# esta en primer plano.

set -u

destino="net.launchpad.ulauncher"
ruta="/net/launchpad/ulauncher"
metodo="net.launchpad.ulauncher.toggle_window"

# La ventana esta en primer plano?
#
# El criterio es focusHistoryID == 0 (la ventana enfocada). No sirve el
# campo mapped/visible: en Wayland la ventana sigue existiendo con
# mapped=true aunque ulauncher la oculte, y el tamano tampoco cambia
# (606x76 tanto visible como oculta).
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
    # Esta abierta: se cierra matando el proceso. Ulauncher vuelve a
    # arrancar oculto en la siguiente pulsacion.
    pkill -x ulauncher 2>/dev/null || true
    pkill -x .ulauncher-wrap 2>/dev/null || true
    exit 0
fi

# No esta abierta: si el daemon ya vive, se muestra con el toggle.
if pgrep -x ".ulauncher-wrap" >/dev/null 2>&1; then
    if dbus-send --session --dest="$destino" "$ruta" "$metodo" >/dev/null 2>&1; then
        exit 0
    fi
fi

# El daemon no vive (se ha muerto por el SIGSEGV de Python 3.14, o no
# ha arrancado): se relanza y se espera a que registre.
pkill -x ulauncher 2>/dev/null || true
pkill -x .ulauncher-wrap 2>/dev/null || true
sleep 0.3

ulauncher --no-window-shadow >/dev/null 2>&1 &

for _ in $(seq 1 24); do
    sleep 0.25
    if dbus-send --session --dest="$destino" "$ruta" "$metodo" >/dev/null 2>&1; then
        exit 0
    fi
done

exit 0
