#!/usr/bin/env bash
#
# Uso de CPU por hilo logico, en formato compacto para la barra.
#
# Lee /proc/stat, que expone una linea "cpuN" por cada CPU logica. En el
# i7-4790 hay 4 nucleos fisicos con SMT (2 hilos por nucleo), asi que las
# lineas van en orden lineal:
#
#   cpu0, cpu1 -> nucleo fisico 0 (hilo 0 y su hermano SMT)
#   cpu2, cpu3 -> nucleo fisico 1
#   cpu4, cpu5 -> nucleo fisico 2
#   cpu6, cpu7 -> nucleo fisico 3
#
# El formato usa bloques de 3 caracteres por hilo: un guion para el
#Thread menos de 25%, un numero para 25-99%, y "!" a partir del 100%.
# Asi los 8 hilos ocupan 24 caracteres: se lee de un vistazo si la carga
# esta repartida o si un solo hilo esta saturado (que es lo que
# realmente molesta al usuario, y lo que el % global no enseña).
#
# El porcentaje se calcula con la diferencia entre dos lecturas de
# /proc/stat separadas por un intervalo: el kernel da valores ACUMULADOS
# desde el arranque, no el uso instantaneo.

set -u

INTERVAL=1

read_stats() {
    # Imprime por cada CPU logica: los jiffies activos y los totales.
    # El campo 4 son los jiffies de user+nice, el 5 los de system, y el
    # 8 el idle. Activo = total - idle.
    awk '/^cpu[0-9]/ {
        idle = $5 + $6
        total = $2 + $3 + $4 + $5 + $6 + $7 + $8
        printf "%s %d %d\n", $1, total, idle
    }' /proc/stat
}

TMP1=$(mktemp)
TMP2=$(mktemp)
trap 'rm -f "$TMP1" "$TMP2"' EXIT

read_stats > "$TMP1"
sleep "$INTERVAL"
read_stats > "$TMP2"

# paste une las dos lecturas por numero de CPU y awk calcula el
# porcentaje de uso de cada una.
OUT=$(paste "$TMP1" "$TMP2" | awk '
    {
        total_delta = $5 - $2
        idle_delta  = $6 - $3
        if (total_delta <= 0) { pct = 0 }
        else {
            pct = int(((total_delta - idle_delta) * 100) / total_delta)
            if (pct < 0) pct = 0
            if (pct > 100) pct = 100
        }
        # 3 caracteres por hilo: "-" (<25%), digito (25-99%), "!" (100%)
        if (pct >= 100)      s = "!"
        else if (pct >= 25)  s = pct ""
        else                 s = "-"
        line = line s " "
    }
    END { gsub(/ +$/, "", line); print line }
')

printf '%s' "$OUT"
