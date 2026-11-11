# Optimización del sistema — resumen

Documento de referencia de los cambios aplicados el 2026-11-10. El
objetivo era el mismo que planté el usuario: "tengo 32 GB de RAM y parece
que tengo muy menos", más la duda de por qué la CPU solo mostraba un
porcentaje agregado.

---

## 1. Diagnóstico: la RAM no estaba mal, el sistema sí

Medición inicial:

| Métrica | Antes | Después |
|---|---|---|
| RAM usada | 27 GB / 31 GB | 10 GB / 31 GB |
| RAM libre | 271 MB | 17 GB |
| Swap (zram) usado | 8.5 GB | 857 MB |
| Presión de I/O (`io.full avg10`) | 3.80 | — |

### Causa raíz 1: la VM se comía 14 GB

El proceso `qemu-system-x86_64` (la VM `INDRA-MSC`) tenía **13.5 GB de
RSS resident** de los 27 GB usados por el sistema.

El detalle importante: la VM declara `virtio-balloon-pci`, pero el
balloon **no estaba devolviendo memoria**. `dommemstat` reportaba:

```
actual 21206016     # 20 GB asignados
unused 20503684     # ... de los cuales el guest NO está usando
```

El guest tenía ~20 GB libres y el host los retenía igualmente. Eso es
memoria hostage por diseño: el host no puede reclaimear RSS de QEMU.

**Medida de confirmación:** con la VM apagada, la RAM usada bajó de
27 GB a 10 GB. No había ningún "memory leak" — había una VM configurada
para pedir más de lo que usa.

**Solución aplicada:**
- RAM de la VM: 20 GB → **12 GB** (`setmaxmem` + definición persistente
  en libvirt).
- Topología de CPU corregida: `-smp 4,sockets=4,cores=1,threads=1` →
  **1 socket × 4 cores × 1 thread**. Cuatro sockets distintos es la
  peor topología posible para el scheduler: el guest ve cuatro "chips"
  en vez de un chip de cuatro núcleos, y pierde L2/L3 compartido.

### Causa raíz 2: `vm.swappiness = 150` (el máximo)

Este es el hallazgo que más explica la RAM "desaparecida". Con
swappiness 150 el kernel mete en swap **páginas anónimas de las
aplicaciones** de forma preventiva, antes de que haya presión real.

El resultado medido: **8.5 GB de swap**, de los cuales ~7 GB eran
páginas frías de Brave/Zen que cabían de sobra en RAM. Eso no es
"memoria bien usada", es RAM comprida a zstd y puffada a la CPU para
nada — con micro-freezes al tocar una app que estaba en swap.

**Cambio:** `swappiness` 150 → **20**, `vfs_cache_pressure` 100 → **30**,
`min_free_kbytes` → 256 MB.

Con 20, el reclaim normal se hace sobre la *caché* (barato de
recuperar) en vez de sobre las *páginas anónimas* (barato no es), y
zram sigue cubriendo la presión real sin paidiar disco.

### Causa raíz 3: zram al 50%

Con 32 GB de RAM, zram al 50% son 15.6 GB. La VM se come 12 GB fijos y
quedan ~17 GB para el escritorio, los navegadores y OBS. Margen
insuficiente.

**Cambio:** zram al **100%** (32 GB de swap comprimido, que en la
práctica ocupa ~10 GB reales gracias al ratio 3.1x de zstd), y **sin
swap en disco** — con zram delante, el swap en NVMe solo añade latencia
de escritura aleatoria (el `io pressure` ya estaba en `avg10=3.80`).

---

## 2. La CPU: por qué solo veías un porcentaje

**HyprPanel no tenía módulo de CPU por núcleo.** Sus "customModules"
de CPU y RAM eran *placeholders* vacíos que solo leían el valor
agregado de `/proc/stat`. No era un bug de configuración: la
funcionalidad no existía en el panel.

Tu hardware: **i7-4790 — 4 núcleos físicos, 8 hilos (SMT ×2)**.

### Solución implementada

Dos vías, ambas activas:

**a) Módulo nativo `cpu` de Wayle** — con la nueva configuración,
Wayle tiene módulos CPU y RAM **nativos** (no placeholders), con
temperatura, frecuencia y *thresholds* de color por carga. HyprPanel no
podía colorear por carga; Wayle sí:

```toml
[[modules.cpu.thresholds]]
above = 60
icon-color = "status-warning"
label-color = "status-warning"

[[modules.cpu.thresholds]]
above = 85
icon-color = "status-error"
label-color = "status-error"
```

**b) Módulo custom `cpu-cores`** (`dotfiles/wayle/cpu-cores.sh`) —
script que lee `/proc/stat` y calcula el uso de cada uno de los 8
hilos por separado. Formato compacto de 3 caracteres por hilo:

```
30 33 - - 34 - - -
└─┬─┘ └─┬─┘ └─┬─┘ └─┬─┘
  │     │     │     └─ núcleo 3 (hilos 6-7): inactivos
  │     │     └─────── núcleo 2 (hilos 4-5): inactivos
  │     └───────────── núcleo 1 (hilos 2-3): inactivos
  └─────────────────── núcleo 0 (hilos 0-1): 30% y 33% ← los 2 hilos
```

Los pares corresponden a los dos hilos SMT de un mismo núcleo físico,
de modo que se ve de un vistazo si la carga está repartida o concentrada
en un solo hilo — algo que el porcentaje global nunca enseña.

**c) Waybar** — añadido también el desglose `cpu#0` … `cpu#7` en
`dotfiles/waybar/config`, por si se usa waybar en algún momento.

### Governor de CPU

Se mantiene `performance` (decisión del usuario). Añadido un servicio
propio (`cpufreq-latency`) que lo **reafirma** tras el arranque, porque
powertop o un cambio de TTY lo degradan a `powersave` sin avisar.

> Sobre la latencia de transición: con el driver `intel_cpufreq` (que es
> el que reporta este equipo, con `intel_pstate` en modo `passive`) **no
> existe** el fichero `scaling_transition_latency`: solo
> `cpuinfo_transition_latency`, de solo lectura. El valor se fija en el
> kernel con el parámetro de módulo `tsc` y no se cambia en caliente.
> El default del driver son 20000 µs ≈ 70.000 ciclos a 3.6 GHz, de sobra
> para el escritorio, así que no se fuerza un boot parameter para ello.

---

## 3. Migración HyprPanel → Wayle

**HyprPanel fue archivado en nixpkgs**: el paquete lanza un error
(`'hyprpanel' has been archived, consider using 'wayle' instead`) y
**bloquea cualquier `nixos-rebuild`**. El sistema estaba atascado en un
commit de junio que ya no reconstruía.

Alternativas evaluadas:

| Opción | Resultado |
|---|---|
| Fijar nixpkgs a `nixos-25.11` | ❌ Incompatible: los módulos de nixpkgs 25.11 usan `services.displayManager.generic`, que solo existe en ≥26.05 |
| Quitar hyprpanel y usar solo waybar | ⚠️ Funcional, pero se pierde el centro de notificaciones y el OSD |
| **Migrar a Wayle** | ✅ **Elegido**: sustituto oficial, Rust+GTK4, mucho más ligero |

Wayle es además una mejora técnica real: HyprPanel era GTK/JS con un
**motor web entero** por debajo (y así se explica parte del consumo de
RAM de tu escritorio); Wayle está escrito en Rust.

### Archivos

- `dotfiles/wayle/config.toml` — configuración nueva (TOML), replicando
  el layout exacto de hyprpanel.
- `dotfiles/wayle/cpu-cores.sh` — script del detalle por núcleo.
- `dotfiles/hyprpanel/` — **eliminado**.
- `dotfiles/hypr/hyprland.conf` y `.lua` — autostart y atajo
  `$seccMod+A` actualizados a `wayle panel start` / `wayle panel settings`.
- `home.nix` — `services.wayle` con `builtins.fromTOML`, de modo que el
  TOML del repo es la **única** fuente de verdad.

### Tema

La paleta **no** se define en el TOML: el módulo `wayle/hm.nix` de
nixpkgs la conecta con **stylix**, así que Wayle usa exactamente el
mismo catppuccin mocha que el resto del escritorio y ambos cambian a
la vez. Definirla en el TOML daba conflicto de valores.

---

## 4. Otros cambios

### Brave → módulo propio (modules/brave.nix)

`pkgs.brave` fue **eliminado de nixpkgs** (sin mantenedores para
resolver problemas de seguridad) y bloqueaba el rebuild.

Pero Brave no selostaba: estaba instalado desde el `.deb` oficial de
GitHub, desempaquetado con `dpkg` y envuelto con `wrap-gapps-hook`. Ese
`.drv` seguía en el store pero su entrada en el sistema no era
reconstruible.

**Solución:** `modules/brave.nix` rehace exactamente ese paquete — el
`.deb` oficial de Brave 1.91.175 (la misma versión que tenías), extraído
con `dpkg-deb --fsys-tarfile | tar` y envuelto con `wrapGAppsHook3`.

Detalles no triviales del empaquetado:

| Detalle | Por qué |
|---|---|
| `dpkg-deb --fsys-tarfile \| tar -x -C $out` en vez de `dpkg-deb -x` | El `.deb` trae `chrome-sandbox` con bit setuid (rwsr-xr-x), que Nix no permite en el store. `dpkg-deb -x` aborta al tocarlo. |
| `mkdir -p $out` antes de extraer | Si no existe, `tar -C $out` falla con "Cannot open" y `dpkg-deb` queda con un broken pipe. |
| El binario está en `opt/brave.com/brave/` | No en `usr/lib/brave/`: el symlink en `$out/bin` apunta a `../opt/brave.com/brave/brave`. |
| `wrapGAppsHook3` y no `wrapGAppsHook` | Brave es GTK3. Además es un *setup-hook*: se aplica solo al final de la fase de instalación vía `fixupOutputHooks`, no se invoca a mano desde `installPhase`. |

Consecuencia: el sandbox de Chrome no puede usar el helper setuid, así
que Brave necesita `--no-sandbox`. Es el precio de que un navegador con
su propio helper setuid viva en el store de Nix. El perfil, las
extensiones y la sincronización no se ven afectados.

### flatpak-repo fallaba en cada arranque

```
error: Can't load uri https://flathub.org/repo/flathub.flatpakrepo:
[6] Could not resolve hostname
```

El servicio corría en `multi-user.target`, que se alcanza **antes** de
que la red tenga DNS. Ahora espera a `network-online.target`, reintenta
y sale con código 0 si aun así falla (no es un error del sistema, solo
un remoto que se puede añadir a mano).

### flake.lock desactualizado

Estaba en un commit de nixpkgs de junio con un `.drv` corrupto en el
store (`base16-schemes`). Actualizado `nixpkgs` y `stylix`.

---

## 5. Hyprland: el aviso de "autogenerated config" y el wallpaper

### El aviso de autogenerado

Después del rebuild, Hyprland se quejaba de usar un fichero
autogenerado:

```
Warning: You're using an autogenerated config! Edit the config file to
get rid of this message.
```

El log de Hyprland (`/run/user/1000/hypr/<hash>/hyprland.log`) da la
clave:

```
DEBUG: [Config::initConfigManager] [cfg] Regular config at /home/pozito/.config/hypr/hyprland.lua
WARN:  [Config::Lua::CConfigManager::generateDefaultConfig] No config file found; attempting to generate.
```

**Causa:** `home.nix` tenía `useHyprlandLua = false`, así que home-manager
**no desplegaba** `hyprland.lua` ni `colors.lua`. Hyprland 0.55+ busca el
`.lua` en `~/.config/hypr/`, así que el que había (un fichero regular,
no symlink) lo detectaba, pero al faltar `colors.lua` —que su
`require("colors")` necesita— no podía cargarlo y **sobrescribía el
fichero con su config autogenerado**, que a su vez ignoraba el
`hyprland.conf`.

**Solución:** `useHyprlandLua = true`. Home-manager despliega
`hyprland.lua` y `colors.lua` como symlinks al store, y Hyprland usa tu
config Lua real (230 líneas).

### Por qué no salía el fondo de pantalla

El wallpaper lo pone hyprpaper, y hyprpaper lo lanzaba el autostart. El
autostart estaba enganchado al evento `hyprland.start`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    ...
end)
```

Ese evento **se dispara una sola vez**, cuando arranca Hyprland. Como
el `.lua` aún no estaba desplegado en ese instante (lo despliega
home-manager en el rebuild), el evento ya había pasado y el autostart se
perdía para siempre: sin hyprpaper, sin ulauncher, sin agente de polkit.

**Solución:** lanzar los programas directamente al cargar el config, en
vez de depender del evento:

```lua
local function autostart(cmd)
    hl.exec_cmd("sh -c '" .. cmd .. " >/dev/null 2>&1 &'")
end

autostart("sh ~/.config/hypr/ipc-compat.sh")
autostart("hyprpaper")
autostart("hyprpolkitagent")
autostart("wayle panel start")
autostart("ulauncher --hide-window --no-window-shadow")
```

El `&` final es imprescindible: `hl.exec_cmd` espera a que el comando
termine, y hyprpaper y ulauncher son daemons que no terminan nunca.
Como el autostart está en el cuerpo del config (no en un evento), se
ejecuta en cada carga del config, y es idempotente.

### Los atajos que no funcionaban

**Causa:** Hyprland 0.57 carga **a la vez** el `.conf` y el `.lua`. Con
ambos ficheros presentes:

- El autostart se duplicaba (`exec-once` en el `.conf` + `hl.exec_cmd`
  en el `.lua`).
- Los binds se duplicaban y **se contradecían**: el `.lua` definía
  `ALT+1` como *mover la ventana* al workspace 1, y el `.conf` definía
  `ALT+1` como *cambiar al* workspace 1. Dos definiciones opuestas de
  la misma tecla: el resultado era impredecible.

**Solución:** que solo se cargue el `.lua`. El `.conf` se despliega con
otro nombre para que quede como backup consultable, sin que Hyprland
lo detecte:

```nix
".config/hypr/hyprland.conf.bak" = {
  source = ./dotfiles/hypr/hyprland.conf;
};
```

Para volver al modo legacy: renombrar a `hyprland.conf` y poner
`useHyprlandLua = false`.

Verificación: `hyprctl binds` devuelve 39 binds, **todos** con
`dispatcher: HL.Dispatcher(exec_cmd)` (el dispatcher propio del
formato Lua) y **cero** con el `exec,` legacy del `.conf`.

### Nota sobre el modo Lua

En modo Lua **los dispatchers clásicos dejan de existir**, así que el
panel no puede cambiar de workspace al pulsar en el. El script
`ipc-compat.sh` crea los enlaces del socket IPC que Hyprland 0.55 movió
(`<instancia>/socket` → `<instancia>/.socket.sock`) y es lo que
mantiene esa parte funcionando.

### Sobre `exec_cmd` con argumentos

El dispatcher `exec_cmd` recibe **un único string** y lo ejecuta a
través de un shell, así que `"hyprshot -m region --clipboard-only"`
funciona. Lo que **no** funciona es:

- Pasar el comando como variable sin comillas:
  `hl.dsp.exec_cmd(brave)` → error de sintaxis (bug reportado en el
  foro de Hyprland).
- Escribirlo como código Lua suelto: `hyprctl dispatch exec "wayle
  panel settings"` falla con `')' expected near 'wayle'`, porque el
  dispatcher parsea la cadena como Lua.

Con `fileManager` y `terminal` (variables locales que ya contienen el
nombre del binario) no hay problema: no llevan espacios.

---

## 6. Procesos zombie

10 procesos `<defunct>`, todos hijos de programas de terceros:

| Padre | Origen |
|---|---|
| `ulauncher` | bug de ulauncher |
| `speech-dispatcher` | bug de speech-dispatcher (Flatpak) |
| `pocketbase` | bug de pocketbase (Docker) |

Consumen 0 RAM y no afectan al rendimiento. `SIGCHLD` no los reaping
(los padres no los recogen), así que solo se limpian al reiniciar
dichos programas. **No es un problema de tu configuración.**

---

## 6. Cómo verificar

```bash
# RAM y swap
free -h && swapon --show

# governor y latencia
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_transition_latency

# uso por núcleo (el mismo script del panel)
~/.config/wayle/cpu-cores.sh

# RAM de la VM
virsh dominfo INDRA-MSC | grep -i memory
virsh dommemstat INDRA-MSC

# presión de memoria (PSI)
cat /proc/pressure/memory
```

---

## 7. Pendiente

- **Arranca la VM y comprueba que 12 GB le bastan.** Si al hacer
  compilaciones pesadas se queda corta, se puede subir a 14 GB — el
  balloon ya está configurado y debería devolver la memoria sin
  problema una vez arrancada con la nueva definición.
- **Brave necesita `--no-sandbox`.** El `chrome-sandbox` con bit setuid
  no puede vivir en el store de Nix (el store es inmutable y no admite
  bits especiales). Es el precio de empaquetar el `.deb` oficial.
- **Navegadores abiertos a la vez**: tienes Brave (2.2 GB) y Zen
  (2.5 GB+) con muchas pestañas. Con la VM en 12 GB la presión
  debería bajar bastante, pero cerrar el navegador que no uses sigue
  siendo la palanca más directa.
- **Los clics de la barra no cambian de workspace** (consecuencia del
  modo Lua). Si molesta, la alternativa es volver al `.conf`.
