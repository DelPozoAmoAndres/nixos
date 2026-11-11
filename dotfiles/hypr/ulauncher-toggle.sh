#!/usr/bin/env bash
#
# Muestra u oculta la ventana de ulauncher.
#
# POR QUE NO SE USA "dbus-send" A PELO:
#
# El shim "ulauncher-toggle" del paquete (dbus-send + sleep 0.03 +
# wmctrl -a) es lo que alterna bien. Con solo dbus-send el toggle se
# aplica pero la ventana se queda visible: no llega a completarse.
#
# El error que el shim saca por consola ("Cannot get client list
# properties") viene del "wmctrl -a" final (X11, que en Wayland no
# encuentra la ventana) y es INOFENSIVO: el toggle de antes ya ha hecho
# su trabajo.
#
# QUE SE ANADE AQUI:
#
# Si el daemon de ulauncher ha muerto (hace SIGSEGV a veces con Python
# 3.14, se ve en coredumpctl), el shim no tiene a quien preguntar por
# D-Bus y no hace nada, sin error visible. Esto lo relanza.
#
# No se puede comprobar si el daemon vive con dbus-send: cuando el
# proceso muere, el nombre del bus sigue registrado y dbus-send sale con
# codigo 0. Hay que mirar al proceso (con el prefijo del wrapper de
# Nix: ".ulauncher-wrap").

set -u

# El daemon vive?
if ! pgrep -x ".ulauncher-wrap" >/dev/null 2>&1; then
    # Esta muerto (crash). Se relanza. Se lanza SIN --hide-window
    # porque con ese flag la ventana nunca se crea y el toggle no
    # tendria nada que mostrar.
    pkill -x ulauncher 2>/dev/null || true
    pkill -x .ulauncher-wrap 2>/dev/null || true
    sleep 0.3

    ulauncher --no-window-shadow >/dev/null 2>&1 &

    # Se espera a que la ventana exista.
    for _ in $(seq 1 40); do
        sleep 0.25
        if hyprctl clients -j 2>/dev/null | grep -q '"ulauncher"'; then
            break
        fi
    done

    # Y se espera a que se asiente antes de ocultarla.
    sleep 1

    # Se oculta con el toggle, para dejar el daemon en el estado en el
    # que el atajo alterna de forma instantanea.
    ulauncher-toggle >/dev/null 2>&1

    # Y se vuelve a mostrar: el usuario ha pulsado el atajo, lo que
    # espera es ver la ventana, no tener que pulsar dos veces.
    sleep 0.3
    ulauncher-toggle >/dev/null 2>&1
    exit 0
fi

# El daemon vive: el toggle de siempre.
ulauncher-toggle >/dev/null 2>&1

exit 0
