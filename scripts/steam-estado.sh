#!/usr/bin/env bash
#
# Estado de la configuracion de Steam: que juegos usan que Proton y
# que versiones hay instaladas.
#
# Se ejecuta con Steam CERRADO: el cliente reescribe config.vdf al
# salir y descartaria los cambios hechos mientras esta abierto.

set -u

STEAM_DIR="$HOME/.local/share/Steam"
COMPAT="$STEAM_DIR/compatibilitytools.d"
CONFIG="$STEAM_DIR/config/config.vdf"
LOCALCONFIG=$(ls "$STEAM_DIR"/userdata/*/config/localconfig.vdf 2>/dev/null | head -1)

echo "═══════════════════════════════════════════════════════"
echo " VERSIONES DE PROTON INSTALADAS"
echo "═══════════════════════════════════════════════════════"
if [ -d "$COMPAT" ]; then
    for d in "$COMPAT"/*/; do
        [ -d "$d" ] || continue
        n=$(basename "$d")
        v=$(cat "$d/version" 2>/dev/null | head -1 | awk '{print $1}')
        printf "  %-24s %s\n" "$n" "${v:-?}"
    done
else
    echo "  (directorio no encontrado)"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " JUEGOS Y PROTON ASIGNADO"
echo "═══════════════════════════════════════════════════════"

if [ -f "$CONFIG" ]; then
    # Nombres de los juegos desde los appmanifest.
    declare -A nombres=()
    for m in "$STEAM_DIR"/steamapps/appmanifest_*.acf; do
        [ -f "$m" ] || continue
        id=$(basename "$m" | sed 's/appmanifest_//; s/\.acf//')
        n=$(grep -m1 '"name"' "$m" | sed 's/.*"name"[ \t]*"\(.*\)".*/\1/')
        nombres[$id]="$n"
    done

    python3 - "$CONFIG" <<'PYEOF'
import re, sys, os, glob

cfg = open(sys.argv[1], encoding='utf-8', errors='replace').read()
m = re.search(r'"CompatToolMapping"\s*\{(.*?)\n\t\t\t\}', cfg, re.S)

nombres = {}
for mf in glob.glob(os.path.expanduser(
        '~/.local/share/Steam/steamapps/appmanifest_*.acf')):
    try:
        t = open(mf, encoding='utf-8', errors='replace').read()
        i = os.path.basename(mf).replace('appmanifest_', '').replace('.acf', '')
        n = re.search(r'"name"\s+"([^"]+)"', t)
        if n: nombres[i] = n.group(1)
    except Exception:
        pass

if not m:
    print("  (sin CompatToolMapping)")
    sys.exit(0)

apps = re.findall(r'"(\d{4,6})"\s*\{\s*"name"\s*"([^"]+)"', m.group(1))
if not apps:
    print("  (ningun juego con Proton forzado)")
    sys.exit(0)

instalados = set()
compat_dir = os.path.expanduser('~/.local/share/Steam/compatibilitytools.d')
if os.path.isdir(compat_dir):
    instalados = {d for d in os.listdir(compat_dir)
                   if os.path.isdir(os.path.join(compat_dir, d))}

for appid, proton in sorted(apps, key=lambda x: nombres.get(x[0], x[0])):
    nombre = nombres.get(appid, '?')
    marca = '' if proton in instalados else '   <-- NO INSTALADO'
    print(f"  {nombre[:34]:34} {proton}{marca}")
PYEOF
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " LAUNCH OPTIONS"
echo "═══════════════════════════════════════════════════════"
if [ -f "$LOCALCONFIG" ]; then
    python3 - "$LOCALCONFIG" <<'PYEOF2'
import re, sys, os, glob

f = sys.argv[1]
txt = open(f, encoding='utf-8', errors='replace').read()

nombres = {}
for mf in glob.glob(os.path.expanduser(
        '~/.local/share/Steam/steamapps/appmanifest_*.acf')):
    try:
        t = open(mf, encoding='utf-8', errors='replace').read()
        i = os.path.basename(mf).replace('appmanifest_', '').replace('.acf', '')
        n = re.search(r'"name"\s+"([^"]+)"', t)
        if n: nombres[i] = n.group(1)
    except Exception:
        pass

# appid -> LaunchOptions: se buscan los "LaunchOptions" y se mira el
# appid de la seccion que los contiene.
# Cada "LaunchOptions" va dentro del bloque de su appid. Se recorre
# linea a linea y se busca el appid hacia atras (el mas cercano por
# encima), porque la estructura de indentacion de los vdf de Steam
# cambia segun la seccion.
lineas = txt.split('\n')
appids = []   # (numero_de_linea, appid)
for i, linea in enumerate(lineas):
    # Solo cuentan los appids "sueltos" (un numero y nada mas): las
    # lineas del tipo '"730"  "4a00000..."' son otro tipo de dato.
    # OJO con los cuantificadores {n,m} en regex: se aplican al
    # caracter anterior. "\t{4,6}" seria "un tab seguido de 4 a 6
    # letras t", y "\d{4,6}" algo similar. Por eso se agrupa el tab
    # ("(?:\t){4,6}") y el numero se pide con "\d+".
    m_id = re.match(r'^(?:\t){4,6}"(\d+)"\s*$', linea)
    if m_id:
        appids.append((i, m_id.group(1)))

for i, linea in enumerate(lineas):
    m_lo = re.search(r'"LaunchOptions"\s+"([^"]*)"', linea)
    if not (m_lo and m_lo.group(1).strip()):
        continue
    appid = '?'
    for j, aid in reversed(appids):
        if j < i:
            appid = aid
            break
    n = nombres.get(appid, appid)
    print(f"  {n[:32]:32} {m_lo.group(1)}")
PYEOF2
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " NOTAS"
echo "═══════════════════════════════════════════════════════"
cat <<'EOF'
  CS2 (730) tiene build NATIVO en Linux. Valve lo soporta y reporta
  problemas de VAC/matchmaking al forzar Proton, especialmente con
  GE-Proton. Se deja nativo, con SteamLinuxRuntime sniper.

  Para CS2 en un monitor de 165Hz:
    - Modo video: pantalla completa
    - Resolucion: nativa (1920x1080 en el DP-1)
    - V-Sync: desactivado
    - NVIDIA Reflex: activado
    - Sombras: medias o bajas
    - Detalle de modelo/textura: bajo o medio
    - Detalle de shaders: bajo
    - Iluminacion ambiental: desactivada
    - HDR: rendimiento

  Para actualizar el Proton:
    protonup -t GE-Proton11-12 -d ~/.local/share/Steam/compatibilitytools.d

  Para ver el uso de GPU en un juego:
    - Con gamescope: %command% dentro de gamescope
    - Con mangohud: ENABLE_MANGOHUD=1 %command%
EOF
