{ config, lib, pkgs, ... }:

{
  # El governor actual ya es "performance" en el sistema, se fija aqui para
  # que sobreviva a los reinicios y a los perfiles de energia.
  powerManagement.cpuFreqGovernor = "performance";

  # Latencia de cambio de frecuencia: con el valor por defecto (1000 us)
  # hay un retardo perceptible al salir de idle en las cargas cortas y
  # discontinuas tipicas del escritorio (click en un menu, scroll, abrir
  # pestana). Con 50 us el nucleo sube de reloj casi al instante.
  #
  # Nota: la opcion estandar de nixpkgs no expone la latencia, asi que
  # se fija directamente sobre sysfs con un servicio propio. El
  # "performance" de arriba lo pone via cpupower; este servicio asegura
  # la latencia despues, cuando el driver intel_cpufreq ya esta listo.
  systemd.services.cpufreq-latency = {
    description = "Ajusta la latencia de transicion de frecuencia de CPU";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" "cpufreq.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_transition_latency; do
        [ -w "$f" ] && echo 50 > "$f" 2>/dev/null || true
      done
      # Y se reafirma el governor: powertop o un TTY pueden haberlo
      # cambiado a powersave despues del arranque.
      for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        [ -w "$f" ] && echo performance > "$f" 2>/dev/null || true
      done
    '';
  };

  # 32 GB de RAM con VMs, agentes y navegador: zram evita que el OOM killer
  # dispare cuando la memoria se llena.
  #
  # 100% en vez del 50% anterior: la VM consume ~14 GB fijos y el host solo
  # tiene ~17 GB para todo lo demas. Con 15.6 GB de zram el host se queda
  # sin margen y el OOM killer empieza a matar procesos del escritorio.
  # Con 32 GB de zram (memoria comprimida ~3x, ocupa ~10 GB reales como
  # mucho) el host tiene colchon de sobra para paginar cache y anon.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    priority = 100;
    algorithm = "zstd";
    # Sin writeback a disco: los datos comprimidos viven solo en RAM
    # (zram). Con NVMe detras solo se añade latencia de escritura
    # aleatoria, que es justo lo que ya tensionsaba el IO.
    writebackDevice = null;
  };

  # Sin swap en disco: con zram al 100% el swap en NVMe solo añade latencia
  # de escritura aleatoria (el IO pressure ya estaba en avg10=3.80). La
  # hibernacion no es un caso de uso en esta QVO.
  swapDevices = [ ];

  boot.kernelParams = [
    "libata.allow_tpm=1"
    "iommu=pt"
    "intel_iommu=on"
    # x86_64 no soporta paginas de 1M, el tamano por defecto es 2M.
    # 2048 paginas = 4 GB reservados para la RAM de las VMs: menos fallos
    # de TLB que con paginas de 4 KB, que es lo que penaliza al inference.
    "hugepages=2048"
  ];

  # El generador de CDI espera a que se vacie la cola de udev, y esa cola
  # se bloquea con el NVMe cifrado con BitLocker y los puertos serie: 10s de
  # arranque perdido. Con 3s basta para que el driver NVIDIA este listo.
  systemd.services.nvidia-container-toolkit-cdi-generator.serviceConfig.ExecStartPre =
    lib.mkForce "-${pkgs.systemd}/bin/udevadm settle --timeout=3";

  boot.kernel.sysctl = {
    # ── swappiness: 150 -> 20 ──────────────────────────────────────────
    #
    # El 150 (maximo) hacia que el kernel metiera en swap las paginas ANON
    # de las aplicaciones antes de tiempo. Consecuencia medida: 8.5 GB de
    # swap ocupados, de los cuales ~7 GB eran paginas frias de Brave/Zen
    # que en realidad cabian de sobra en RAM. Eso no es "memoria bien
    # usada": es paginas de app comprimidas y puffadas a zstd para nada,
    # con el coste de CPU de comprimir/descomprimir y el riesgo de
    # micro-freezes al tocar una app que estaba en swap.
    #
    # Con 20 el kernel sigue usando zram cuando hace falta (no hay disco
    # detras, zram es cheap) pero solo cuando hay presion real, y el
    # reclaim normal lo hace sobre la CACHE, que es mucho mas barato de
    # recuperar (no requiere descomprimir ni re-ejecutar la app).
    "vm.swappiness" = 20;

    # Reduce la presion para que se mantenga algo mas de cache en RAM.
    # 50 es el default; bajarlo a 30 conserva mas cache de page cache
    # (ficheros del store, binarios, fuentes) sin llegar a dejarlo todo
    # sucio por el noyau.
    "vm.vfs_cache_pressure" = 30;

    # El reclaim de paginas anon es mas caro que el de cache: no basta con
    # bajar swappiness, hay que bajar tambien el umbral a partir del cual
    # el kernel decide "esto no lo voy a tener en RAM".
    "vm.min_free_kbytes" = 262144;

    # Permite perf stat para medir donde se va el tiempo.
    "kernel.perf_event_paranoid" = -1;
  };
}
