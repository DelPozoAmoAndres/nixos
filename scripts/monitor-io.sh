#!/usr/bin/env bash
#
# Mide el impacto del I/O durante una descarga de Steam, sin cargar el
# disco.
#
# NO se usa "du" sobre el directorio de descarga: con 67 GB pendientes,
# du recorre todo el arbol cada vez y satura el disco el mismo (que es
# justo lo que hay que medir). En su lugar se mira el tamaño del
# fichero de progreso que escribe Steam, que es un fichero normal.
#
# Uso: monitor-io.sh [segundos]

set -u

SEG="${1:-120}"
PROG=$(ls -t /home/pozito/.local/share/Steam/steamapps/downloading/state_*.patch 2>/dev/null | head -1)
[ -z "$PROG" ] && PROG=$(ls -t /home/pozito/.local/share/Steam/steamapps/downloading/*/state_*.patch 2>/dev/null | head -1)

if [ -z "$PROG" ]; then
    echo "No encuentro el fichero de progreso de Steam."
    echo "Los que hay:"
    find /home/pozito/.local/share/Steam/steamapps/downloading -maxdepth 2 -name "*.patch" 2>/dev/null | head -5
    exit 1
fi

echo "Fichero de progreso: $PROG"
echo
printf "%-8s %-10s %-8s %-8s %-8s\n" "t" "MB/s" "en_D" "load" "io_avg10"
printf -- "-------- ---------- -------- -------- --------\n"

prev_bytes=$(stat -c%s "$PROG" 2>/dev/null || echo 0)
prev_t=$(date +%s)

for i in $(seq 1 "$SEG"); do
    sleep 1
    now_t=$(date +%s)
    now_bytes=$(stat -c%s "$PROG" 2>/dev/null || echo 0)
    dt=$(( now_t - prev_t ))
    [ "$dt" -eq 0 ] && dt=1
    delta=$(( now_bytes - prev_bytes ))
    mbs=$(( delta / 1024 / dt ))

    d_state=$(ps -eo stat --no-headers 2>/dev/null | grep -c 'D')
    load=$(cut -d' ' -f1 /proc/loadavg)
    io=$(awk '/^some/{for(i=1;i<=NF;i++) if($i ~ /^avg10=/){split($i,a,"="); print a[2]; exit}}' /proc/pressure/io 2>/dev/null)

    printf "%-8s %-10s %-8s %-8s %-8s\n" "${now_t}" "${mbs} MB/s" "$d_state" "$load" "$io"

    prev_bytes=$now_bytes
    prev_t=$now_t
done
