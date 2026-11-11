#!/usr/bin/env bash
#
# Muestra u oculta la ventana de ulauncher.
#
# POR QUE HACE FALTA ESTE SCRIPT:
#
# El shim "ulauncher-toggle" del paquete llama al toggle por D-Bus y
# luego hace un "wmctrl -a" (X11) que en Wayland no funciona. El error
# que sale por consola ("Cannot get client list properties") viene de ahi
# y es inofensivo: el toggle de antes ya ha hecho su trabajo.
#
# El problema es otro: si el daemon de ulauncher ha muerto (hace
# SIGSEGV de vez en cuando con Python 3.14, se ve en coredumpctl), el
# toggle no tiene a quien preguntar por D-Bus y no hace nada, sin error
# visible. Esto lo relanza.
#
# NO se mata el proceso en el caso normal: solo si el daemon no
# responde, que es cuando esta muerto de verdad.

set -u

destino="net.launchpad.ulauncher"
ruta="/net/launchpad/ulauncher"
metodo="net.launchpad.ulauncher.toggle_window"

# El daemon responde? (dbus-send sale con codigo != 0 si no hay nadie
# escuchando en ese nombre de bus).
if dbus-send --session --dest="$destino" "$ruta" "$metodo" >/dev/null 2>&1; then
    exit 0
fi

# No responde: el daemon esta muerto. Se relanza.
#
# Se lanza SIN --hide-window porque con ese flag la ventana nunca se
# crea y el toggle no tendria nada que mostrar. Se oculta despues con
# un toggle, dejando el daemon vivo con la ventana creada (que es el
# estado en el que el atajo alterna de forma instantanea).
pkill -x ulauncher 2>/dev/null || true
pkill -x .ulauncher-wrap 2>/dev/null || true
sleep 0.3

ulauncher --no-window-shadow >/dev/null 2>&1 &

# Se espera a que se registre en D-Bus y se oculta la ventana.
for _ in $(seq 1 24); do
    sleep 0.25
    if dbus-send --session --dest="$destino" "$ruta" "$metodo" >/dev/null 2>&1; then
        break
    fi
done

exit 0
