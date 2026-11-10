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

Se mantiene `performance` (decisión del usuario), pero se corrigen dos
cosas que sí eran problemas:

- **Latencia de transición**: 1000 µs (default) → **50 µs**. El default
  introduce un retardo perceptible al salir de idle en cargas cortas
  (abrir un menú, hacer scroll, cambiar de pestaña).
- **Reafirmación del governor**: un servicio propio (`cpufreq-latency`)
  lo vuelve a fijar a `performance` después del arranque, porque
  powertop o un cambio de TTY lo degradan a `powersave` sin avisar.

> Nota sobre las opciones: `powerManagement.cpuFreqBoost`,
> `cpuFreqGovernorConfig` y `cpuFreqTransitionLatency` **no existen** en
> esta versión de nixpkgs (26.11). El validador del flake los rechaza.
> Por eso la latencia se fija con un servicio systemd propio sobre
> sysfs.

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

### Brave → Chromium

`brave` también fue **eliminado de nixpkgs** (sin mantenedores para
resolver problemas de seguridad) y bloqueaba el rebuild. Sustituido por
`chromium`: mismo motor, mismo V8, mismas extensiones. Se pierde el
bloqueo de trackers de Brave (recuperable con uBlock Origin).

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

## 5. Procesos zombie

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
- **Brave → Chromium**: si echabas de menos Brave, la alternativa es
  `brave-bin` (fuera de nixpkgs) o una versión de Brave en un canal
  externo.
- **Navegadores abiertos a la vez**: tienes Brave/Chromium (2.2 GB) y
  Zen (2.5 GB+) con muchas pestañas. Con la VM en 12 GB la presión
  la presión debería bajar bastante, pero cerrar el navegador que no uses
  sigue siendo la palanca más directa.
