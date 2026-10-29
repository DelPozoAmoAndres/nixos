{ config, lib, pkgs, ... }:

{
  # El governor actual ya es "performance" en el sistema, se fija aqui para
  # que sobreviva a los reinicios y a los perfiles de energia.
  powerManagement.cpuFreqGovernor = "performance";

  # 32 GB de RAM con VMs, agentes y navegador: zram evita que el OOM killer
  # dispare cuando la memoria se llena.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "zstd";
  };

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
    # Con zram se prefiere intercambiar antes que descartar paginas.
    "vm.swappiness" = 150;
    # Permite perf stat para medir donde se va el tiempo.
    "kernel.perf_event_paranoid" = -1;
  };
}
