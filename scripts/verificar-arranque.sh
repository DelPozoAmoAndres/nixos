#!/usr/bin/env bash
#
# Comprobacion del arranque: verifica que todo funciona DESPUES de
# reiniciar, no solo en la sesion actual.
#
# Uso: verificar-arranque.sh

set -u

fallos=0
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFALLA\033[0m %s\n' "$1"; fallos=$((fallos+1)); }

echo "═══════════════════════════════════════════════════════"
echo " PROCESOS DE FONDO"
echo "═══════════════════════════════════════════════════════"

# OJO: en Nix los procesos pueden llamarse ".ulauncher-wrap" (por el
# wrapper), asi que pgrep -x con el nombre exacto no los encuentra. Se
# busca con el prefijo.
for p in hyprpaper ulauncher hyprpolkitagent; do
    if pgrep -f "$p" >/dev/null 2>&1; then
        ok "$p corriendo"
    else
        fail "$p NO corriendo"
    fi
done

if systemctl --user is-active --quiet wayle.service; then
    ok "wayle.service activo"
else
    fail "wayle.service NO activo"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " WALLPAPER"
echo "═══════════════════════════════════════════════════════"

capas=$(hyprctl layers 2>/dev/null | grep -c "namespace: hyprpaper")
if [ "$capas" -gt 0 ]; then
    ok "hyprpaper con $capas capas de fondo"
else
    fail "hyprpaper sin capas (no hay wallpaper)"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " SOCKETS IPC (clics de la barra)"
echo "═══════════════════════════════════════════════════════"

if ls /run/user/$(id -u)/hypr/*/socket >/dev/null 2>&1; then
    ok "socket IPC enlazado"
else
    fail "socket IPC NO enlazado (los clics de la barra no funcionan)"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " ATAJOS"
echo "═══════════════════════════════════════════════════════"

total=$(hyprctl binds 2>/dev/null | grep -cE "^\s+key:")
lua=$(hyprctl binds 2>/dev/null | grep -c "HL.Dispatcher")
if [ "$total" -gt 0 ]; then
    ok "$total binds cargados ($lua desde el config Lua)"
else
    fail "ningun bind cargado"
fi

if hyprctl binds 2>/dev/null | grep -q "dispatcher: exec,"; then
    fail "hay binds del .conf legacy (se cargan los dos configs)"
else
    ok "solo el config Lua"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " BARRA (wayle)"
echo "═══════════════════════════════════════════════════════"

barras=$(hyprctl layers 2>/dev/null | grep -c "namespace: wayle-bar")
if [ "$barras" -eq 1 ]; then
    ok "barra en un solo monitor (DP-1)"
elif [ "$barras" -gt 1 ]; then
    fail "barra en $barras monitores (deberia ser solo en el DP-1)"
else
    fail "no hay barra"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " NAVEGADORES"
echo "═══════════════════════════════════════════════════════"

if timeout 15 brave --version >/dev/null 2>&1; then
    ok "brave arranca ($(brave --version 2>/dev/null | head -1))"
else
    fail "brave no arranca: $(timeout 10 brave --version 2>&1 | head -1)"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " MEMORIA"
echo "═══════════════════════════════════════════════════════"

free -h | awk '/^Mem:/ {printf "  RAM: %s usados de %s\n", $3, $2}'
free -h | awk '/^Swap:/ {printf "  Swap: %s usados de %s\n", $3, $2}'
printf '  swappiness: %s\n' "$(sysctl -n vm.swappiness)"
printf '  governor:   %s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"

echo
echo "═══════════════════════════════════════════════════════"
if [ "$fallos" -eq 0 ]; then
    echo -e " \033[32mTODO CORRECTO\033[0m"
else
    echo -e " \033[31m$fallos PROBLEMA(S)\033[0m"
fi
echo "═══════════════════════════════════════════════════════"

exit $fallos
