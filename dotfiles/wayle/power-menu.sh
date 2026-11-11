#!/usr/bin/env bash
#
# Menu de apagado para el boton de power del panel.
#
# El modulo "power" de wayle solo trae el icono: el menu de apagado,
# reinicio y sesion lo pone HyprPanel y hay que montarlo a mano. La
# accion se invoca desde el click del boton (modules.power.left-click).
#
# Se usa "wofi" si esta disponible (menu flotante, con iconos) y se
# recurre a "yad" o "zenity" si no. Si no hay ninguno, se apaga
# directamente (preguntando por terminal no tiene sentido en un menu
# grafico).

set -u

opciones=(
    "Apagar"
    "Reiniciar"
    "Cerrar sesión"
    "Bloquear pantalla"
)

# Buscar un lanzador de menus disponible.
for lanzador in wofi yad zenity; do
    if command -v "$lanzador" >/dev/null 2>&1; then
        FOUND="$lanzador"
        break
    fi
done

if [ -z "${FOUND:-}" ]; then
    # Sin menu grafico: se apaga directamente.
    systemctl poweroff
    exit 0
fi

case "$FOUND" in
    wofi)
        choice=$(wofi --dmenu --hide-input --prompt "Sesión" \
            --insensitive \
            "${opciones[@]}" 2>/dev/null)
        ;;
    yad)
        choice=$(yad --list --title="Sesión" --separator="" \
            --column="Acción" "${opciones[@]}" 2>/dev/null)
        ;;
    zenity)
        choice=$(zenity --list --title="Sesión" \
            --column="Acción" "${opciones[@]}" 2>/dev/null)
        ;;
esac

case "$choice" in
    "Apagar")
        systemctl poweroff
        ;;
    "Reiniciar")
        systemctl reboot
        ;;
    "Cerrar sesión")
        # Termina la sesion de graphical.target, lo que mata la sesion
        # de Hyprland y las apps que dependan de ella.
        loginctl terminate-user "$USER"
        ;;
    "Bloquear pantalla")
        hyprlock
        ;;
esac
