#!/usr/bin/env bash
#
# Activa la compresion zstd en los subvolumenes de btrfs y reescribe los
# datos existentes para que se comprimen.
#
# POR QUE HACE FALTA:
#
# Btrfs guarda la compresion POR SUBVOLUMEN. El fstab pedia
# "compress=zstd" para /home, pero el montaje real era:
#
#   rw,noatime,ssd,space_cache=v2,subvolid=256,subvol=/home
#
# sin la opcion. La razon: /home es un subvolumen ANIDADO dentro de /,
# y al montar / primero (que se hace en el initrd), /home ya queda
# accesible. Cuando se monta encima, el kernel NO puede cambiar la
# compresion de un subvolumen que ya esta montado, y descarta la
# opcion en silencio.
#
# Por eso 263 GB de Documents ocupaban exactamente 263 GB en disco, sin
# comprimir, y el disco estaba al 93%.
#
# QUE HACE:
#
# 1. Aplica "compression=zstd" a cada subvolumen con datos. Esto se puede
#    hacer en caliente con "btrfs property set" y afecta a los ficheros
#    NUEVOS.
#
# 2. Reescribe los datos existentes con "btrfs filesystem defragment",
#    que comprime tambien lo que ya estaba escrito. Es la parte lenta.
#
# Es idempotente: se puede volver a ejecutar sin problema.

set -u

DEVICE="/dev/mapper/luks_btrfs"

# Subvolumenes con datos de usuario.
SUBVOLS=(
    "/"
    "/home"
    "/home/pozito"
    "/home/alnav"
    "/partition-root"
)

echo "==> Aplicando compression=zstd a los subvolumenes"
for sv in "${SUBVOLS[@]}"; do
    if [ -d "$sv" ]; then
        sudo btrfs property set "$sv" compression zstd 2>/dev/null
        printf "    %-16s -> %s\n" "$sv" \
            "$(sudo btrfs property get "$sv" compression 2>/dev/null | head -1)"
    fi
done

echo
echo "==> Espacio antes:"
df -h / | tail -1

echo
echo "==> Comprimiendo los datos existentes (btrfs filesystem defragment)"
echo "    Es la parte lenta: puede tardar horas con hundreds of GB."
echo "    Ctrl-C para parar (lo que no se haya comprimido sigue intacto)."
sudo btrfs filesystem defragment -r /home

echo
echo "==> Espacio después:"
df -h / | tail -1
