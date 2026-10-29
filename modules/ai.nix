{ config, lib, pkgs, ... }:

{
  # ollama queda en segundo plano: la variante con CUDA compila el toolkit
  # completo de NVIDIA (nvcc), horas en este CPU y varios GB de store.
  # La inferencia con GPU se hace con LM Studio, que ya trae su runtime.
  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-cuda;
  #   host = "127.0.0.1";
  #   port = 11434;
  #   environmentVariables = {
  #     OLLAMA_NUM_PARALLEL = "2";
  #     OLLAMA_MAX_LOADED_MODELS = "1";
  #     OLLAMA_FLASH_ATTENTION = "1";
  #     OLLAMA_KEEP_ALIVE = "30m";
  #   };
  # };

  # Cache de modelos fuera del arbol de Home Manager para no inflar el
  # despliegue en cada cambio de configuracion.
  environment.variables = {
    HF_HOME = "/home/pozito/.cache/huggingface";
    TRANSFORMERS_CACHE = "/home/pozito/.cache/huggingface";
  };

  environment.systemPackages = with pkgs; [
    lmstudio
  ];
}
