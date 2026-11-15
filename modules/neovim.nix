{ config, lib, pkgs, ... }:

# Neovim + LazyVim, preparado para el stack habitual de este equipo:
# Go, Angular/TypeScript, JavaScript, Nix y archivos de configuracion.
#
# Enfoque: se usa el modulo `programs.neovim` de Home Manager con el
# paquete `LazyVim` de nixpkgs (v16.0.1) y la lista completa de plugins
# de nixpkgs. Todo se resuelve en tiempo de build, asi que Neovim no
# descarga nada de Internet al arrancar y todo queda reproducible.
let
  # Plugins de nixpkgs.
  #
  # Cada entrada es "nombre-corto = owner/repo = paquete". El "nombre
  # corto" es el que lazy.nvim usa para buscar el plugin en `dev.path`
  # (ver lazy/core/meta.lua: `dev.path .. "/" .. plugin.name`), y el
  # "owner/repo" es el que se usa para resolver los `import = ...` de
  # LazyVim (que conservan la barra).
  #
  # OJO: el nombre NO es el del paquete de nixpkgs. El paquete
  # `snacks-nvim` es en realidad el repo `folke/snacks.nvim`.
  pluginMap = {
    # ─── Core de LazyVim v16 ─────────────────────────────────────────
    "LazyVim" = { repo = "LazyVim/LazyVim"; pkg = pkgs.vimPlugins.LazyVim; };
    "lazy.nvim" = { repo = "folke/lazy.nvim"; pkg = pkgs.vimPlugins.lazy-nvim; };
    "snacks.nvim" = { repo = "folke/snacks.nvim"; pkg = pkgs.vimPlugins.snacks-nvim; };
    # Snacks.explorer sustituye a project.nvim para moverse entre
    # proyectos (el extra util.project de LazyVim necesita telescope o
    # fzf-lua, que no estan instalados).
    "snacks.explorer" = { repo = "folke/snacks.nvim"; pkg = pkgs.vimPlugins.snacks-nvim; };
    "bufferline.nvim" = { repo = "akinsho/bufferline.nvim"; pkg = pkgs.vimPlugins.bufferline-nvim; };
    "catppuccin" = { repo = "catppuccin/nvim"; pkg = pkgs.vimPlugins.catppuccin-nvim; };
    "catppuccin-nvim" = { repo = "catppuccin/nvim"; pkg = pkgs.vimPlugins.catppuccin-nvim; };
    "tokyonight.nvim" = { repo = "folke/tokyonight.nvim"; pkg = pkgs.vimPlugins.tokyonight-nvim; };
    "conform.nvim" = { repo = "stevearc/conform.nvim"; pkg = pkgs.vimPlugins.conform-nvim; };
    "flash.nvim" = { repo = "folke/flash.nvim"; pkg = pkgs.vimPlugins.flash-nvim; };
    "gitsigns.nvim" = { repo = "lewis6991/gitsigns.nvim"; pkg = pkgs.vimPlugins.gitsigns-nvim; };
    "grug-far.nvim" = { repo = "MagicDuck/grug-far.nvim"; pkg = pkgs.vimPlugins.grug-far-nvim; };
    "lazydev.nvim" = { repo = "folke/lazydev.nvim"; pkg = pkgs.vimPlugins.lazydev-nvim; };
    "lualine.nvim" = { repo = "nvim-lualine/lualine.nvim"; pkg = pkgs.vimPlugins.lualine-nvim; };
    "noice.nvim" = { repo = "folke/noice.nvim"; pkg = pkgs.vimPlugins.noice-nvim; };
    "nui.nvim" = { repo = "MunifTanjim/nui.nvim"; pkg = pkgs.vimPlugins.nui-nvim; };
    "persistence.nvim" = { repo = "folke/persistence.nvim"; pkg = pkgs.vimPlugins.persistence-nvim; };
    "plenary.nvim" = { repo = "nvim-lua/plenary.nvim"; pkg = pkgs.vimPlugins.plenary-nvim; };
    "todo-comments.nvim" = { repo = "folke/todo-comments.nvim"; pkg = pkgs.vimPlugins.todo-comments-nvim; };
    "trouble.nvim" = { repo = "folke/trouble.nvim"; pkg = pkgs.vimPlugins.trouble-nvim; };
    "ts-comments.nvim" = { repo = "folke/ts-comments.nvim"; pkg = pkgs.vimPlugins.ts-comments-nvim; };
    "which-key.nvim" = { repo = "folke/which-key.nvim"; pkg = pkgs.vimPlugins.which-key-nvim; };
    "nvim-lint" = { repo = "mfussenegger/nvim-lint"; pkg = pkgs.vimPlugins.nvim-lint; };
    # Mason lo usa LazyVim para instalar LSPs, pero aqui las herramientas
    # vienen de nixpkgs, asi que se desactivan sus instaladores. Aun asi
    # el plugin debe estar presente para que LazyVim no lo descargue.
    "mason.nvim" = { repo = "mason-org/mason.nvim"; pkg = pkgs.vimPlugins.mason-nvim; };
    "mason-lspconfig.nvim" = { repo = "mason-org/mason-lspconfig.nvim"; pkg = pkgs.vimPlugins.mason-lspconfig-nvim; };
    "nvim-lspconfig" = { repo = "neovim/nvim-lspconfig"; pkg = pkgs.vimPlugins.nvim-lspconfig; };
    "nvim-treesitter-textobjects" = { repo = "nvim-treesitter/nvim-treesitter-textobjects"; pkg = pkgs.vimPlugins.nvim-treesitter-textobjects; };
    "nvim-ts-autotag" = { repo = "windwp/nvim-ts-autotag"; pkg = pkgs.vimPlugins.nvim-ts-autotag; };

    # ─── Módulos de mini.nvim ────────────────────────────────────────
    # mini.nvim es un repo con multiples modulos (mini.ai, mini.icons,
    # mini.pairs...). Cada modulo necesita su propio symlink.
    "mini.ai" = { repo = "nvim-mini/mini.ai"; pkg = pkgs.vimPlugins.mini-nvim; };
    "mini.icons" = { repo = "nvim-mini/mini.icons"; pkg = pkgs.vimPlugins.mini-nvim; };
    "mini.pairs" = { repo = "nvim-mini/mini.pairs"; pkg = pkgs.vimPlugins.mini-nvim; };
    "mini.hipatterns" = { repo = "nvim-mini/mini.hipatterns"; pkg = pkgs.vimPlugins.mini-hipatterns; };

    # ─── Extras de lenguaje ──────────────────────────────────────────
    # Go: test runner + debugger.
    "neotest" = { repo = "nvim-neotest/neotest"; pkg = pkgs.vimPlugins.neotest; };
    "nvim-nio" = { repo = "nvim-neotest/nvim-nio"; pkg = pkgs.vimPlugins.nvim-nio; };
    "neotest-golang" = { repo = "fredrikaverpil/neotest-golang"; pkg = pkgs.vimPlugins.neotest-golang; };
    "nvim-dap" = { repo = "mfussenegger/nvim-dap"; pkg = pkgs.vimPlugins.nvim-dap; };
    "nvim-dap-go" = { repo = "leoluz/nvim-dap-go"; pkg = pkgs.vimPlugins.nvim-dap-go; };

    # Markdown.
    "markdown-preview.nvim" = { repo = "iamcco/markdown-preview.nvim"; pkg = pkgs.vimPlugins.markdown-preview-nvim; };
    "render-markdown.nvim" = { repo = "MeanderingProgrammer/render-markdown.nvim"; pkg = pkgs.vimPlugins.render-markdown-nvim; };

    # JSON / schemas.
    "SchemaStore.nvim" = { repo = "b0o/SchemaStore.nvim"; pkg = pkgs.vimPlugins.SchemaStore-nvim; };

    # TypeScript / Angular: completacion.
    "nvim-cmp" = { repo = "hrsh7th/nvim-cmp"; pkg = pkgs.vimPlugins.nvim-cmp; };
    "cmp-git" = { repo = "petertriho/cmp-git"; pkg = pkgs.vimPlugins.cmp-git; };
    "blink.cmp" = { repo = "saghen/blink.cmp"; pkg = pkgs.vimPlugins.blink-cmp; };
    "friendly-snippets" = { repo = "rafamadriz/friendly-snippets"; pkg = pkgs.vimPlugins.friendly-snippets; };

    # Test runner generico (el extra test.core).
    "none-ls.nvim" = { repo = "nvimtools/none-ls.nvim"; pkg = pkgs.vimPlugins.none-ls-nvim; };

    # ─── Utilidades ──────────────────────────────────────────────────
    "gh.nvim" = { repo = "ldelossa/gh.nvim"; pkg = pkgs.vimPlugins.gh-nvim; };
    "litee.nvim" = { repo = "ldelossa/litee.nvim"; pkg = pkgs.vimPlugins.litee-nvim; };
  };

  # Grammars de Tree-sitter que se instalan desde nixpkgs.
  #
  # nvim-treesitter busca los parsers en `stdpath("data")/site/parser`
  # (ver lua/nvim-treesitter/config.lua: `install_dir`). Por eso se
  # enlazan alli como `xdg.dataFile`, de forma que nvim los encuentra
  # sin compilar nada en tiempo de ejecucion.
  #
  # La lista cubre los grammars core de LazyVim (los que pide
  # `ensure_installed`) mas los del stack real del usuario:
  # - angular/scss: los exige el extra de Angular y los proyectos de
  #   Tailwind.
  treeSitterGrammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
    # Core de LazyVim.
    bash
    c
    css
    diff
    dockerfile
    git_config
    git_rebase
    gitattributes
    gitcommit
    gitignore
    html
    javascript
    jsdoc
    json
    # json5 lo pide el extra lang.json de LazyVim (ensure_installed).
    json5
    lua
    luadoc
    luap
    markdown
    markdown_inline
    printf
    python
    query
    regex
    sql
    toml
    tsx
    typescript
    vim
    vimdoc
    xml
    yaml

    # Stack real del usuario.
    angular
    astro
    dtd
    go
    gomod
    gosum
    gowork
    nix
    scss
    svelte
  ];

  # Todos los .so de los grammars en un unico directorio.
  #
  # OJO: el contenido va DIRECTAMENTE en $out (no en $out/parser), porque
  # Home Manager enlaza `source` como el contenido de
  # `~/.local/share/nvim/site/parser`. Si se metiera un subdirectorio
  # "parser" dentro, los .so acabarian en site/parser/parser/ y
  # nvim-treesitter no los encontraria.
  treeSitterParsers = pkgs.runCommand "nvim-treesitter-parsers" { }
    ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (
        map
          (grammar: ''
            for so in ${grammar}/parser/*.so; do
              [ -e "$so" ] && ln -s "$so" $out/$(basename "$so")
            done
          '')
          treeSitterGrammars
      )}
    '';

  # Plugin nvim-treesitter con las queries de los grammars anteriores.
  treesitterPlugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
    angular
    scss
  ]);

  # Arbol de symlinks con los plugins, en los dos formatos que necesita
  # lazy.nvim:
  #
  # 1. "<nombre-corto>"      -> como lo busca lazy.nvim (dev.path/name)
  # 2. "<owner>/<repo>"      -> como lo resuelven los `import` de LazyVim
  #
  # Home Manager NO añade `~/.local/share/nvim/site` al packpath de
  # Neovim (desactiva el packpath de nixpkgs a proposito), asi que los
  # plugins enlazados en `site/pack/hm/start/` no llegan al runtimepath
  # y `import = "lazyvim.plugins"` falla con "No specs found".
  # Arbol de symlinks con los plugins.
  #
  # lazy.nvim busca cada plugin en `dev.path .. "/" .. plugin.name`
  # (ver lazy/core/meta.lua), donde `plugin.name` es el nombre corto que
  # declara el spec: "bufferline.nvim", "mini.ai", "nvim-lint"...
  #
  # Home Manager NO añade `~/.local/share/nvim/site` al packpath de
  # Neovim (desactiva el packpath de nixpkgs a proposito), asi que los
  # plugins enlazados en `site/pack/hm/start/` no llegan al runtimepath
  # y lazy.nvim no los encuentra.
  pluginDir = pkgs.runCommand "lazyvim-plugins" { }
    ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (short: info: ''
            ln -s ${info.pkg} $out/${short}
          '')
          pluginMap
      )}

      # Tree-sitter con los parsers de nixpkgs (angular, scss, etc.).
      ln -s ${treesitterPlugin} $out/nvim-treesitter
    '';

  # Lista plana de todos los plugins para programs.neovim.plugins.
  allPlugins = map (info: info.pkg) (lib.attrValues pluginMap) ++ [ treesitterPlugin ];
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Node y Python son necesarios por algunos plugins (neovim-node-host
    # para el LSP de Angular, pynvim para el host de Python).
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    # ─── Plugins ────────────────────────────────────────────────────────
    plugins = allPlugins;

    # ─── Configuracion de inicio ───────────────────────────────────────
    initLua = ''
      -- ─── Plugins de Nix en el runtimepath ────────────────────────────
      -- lazy.nvim resuelve los `import = "lazyvim.plugins..."` ANTES de
      -- anadir los plugins al runtimepath, asi que hay que ponerlos a
      -- mano primero. Sin esto sale "No specs found for module".
      --
      -- `dev.path` (abajo) le dice a lazy.nvim donde estan los plugins
      -- para que NO descargue nada y los use desde el nix store.
      -- Los plugins de Nix en el runtimepath. Sin esto, lazy.nvim no
      -- encuentra ni los plugins ni los modulos de LazyVim.
      for _, plugin in ipairs(vim.fn.glob("${pluginDir}/*", false, true)) do
        if vim.fn.isdirectory(plugin) == 1 and not vim.tbl_contains(vim.api.nvim_list_runtime_paths(), plugin) then
          vim.opt.runtimepath:append(plugin)
        end
      end

      -- LazyVim con todos los plugins servidos desde nixpkgs.
      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins", dev = true, pin = true },

          -- Snacks.explorer: explorador de archivos nativo de LazyVim
          -- v16. Sustituye al extra util.project, que requeria telescope
          -- o fzf-lua para funcionar.
          {
            "folke/snacks.nvim",
            opts = {
              explorer = { enabled = true },
            },
          },

          -- Los parsers de Tree-sitter los instala nixpkgs, asi que se
          -- anula el instalador de nvim-treesitter: si faltara alguno,
          -- avisa en vez de compilarlo en tiempo de ejecucion (que
          -- fallaria en un store de solo lectura).
          --
          -- LazyVim usa `opts_extend = { "ensure_installed" }`, asi que
          -- los extras AÑADEN grammars a la lista en vez de
          -- reemplazarla. Por eso no basta con poner la lista vacia:
          -- hay que interceptar el `config` del plugin.
          {
            "nvim-treesitter/nvim-treesitter",
            build = false,
            config = function(_, opts)
              require("nvim-treesitter").setup(opts)
              LazyVim.treesitter.get_installed(true)

              -- Avisar de los grammars que falten, sin compilar nada.
              local missing = vim.tbl_filter(function(lang)
                return not LazyVim.treesitter.have(lang)
              end, opts.ensure_installed or {})

              if #missing > 0 then
                LazyVim.error({
                  "Faltan grammars de Tree-sitter: " .. table.concat(missing, ", "),
                  "",
                  "Anadelos en `treeSitterGrammars` (modules/neovim.nix) y reconstruye.",
                })
              end
            end,
          },

          -- Extras de LazyVim que interesan.
          { import = "lazyvim.plugins.extras.lang.go" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.angular" },
          { import = "lazyvim.plugins.extras.lang.svelte" },
          { import = "lazyvim.plugins.extras.lang.astro" },
          { import = "lazyvim.plugins.extras.lang.nix" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.lang.yaml" },
          { import = "lazyvim.plugins.extras.lang.markdown" },
          { import = "lazyvim.plugins.extras.lang.tailwind" },
          { import = "lazyvim.plugins.extras.lang.git" },
          { import = "lazyvim.plugins.extras.lang.docker" },
          { import = "lazyvim.plugins.extras.formatting.prettier" },
          { import = "lazyvim.plugins.extras.linting.eslint" },
          { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
          { import = "lazyvim.plugins.extras.util.gh" },
          { import = "lazyvim.plugins.extras.test.core" },
        },
        dev = {
          path = "${pluginDir}",
          patterns = { "" },
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = { enabled = false },
        rocks = { enabled = false },
        change_detection = { enabled = false },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';

    # ─── Preferencias ───────────────────────────────────────────────────
    extraConfig = ''
      set relativenumber
      set number
      set splitkeep=screen
      set splitright
      set termguicolors
      set mouse=a
    '';

    # ─── Herramientas disponibles dentro de Neovim ──────────────────────
    # LSPs, formatters, linters y utilidades. Los binarios se exponen en
    # el PATH del wrapper de Neovim.
    extraPackages = with pkgs; [
      # Go
      gopls
      gofumpt
      golangci-lint
      delve

      # TypeScript / Angular / JavaScript
      # vtsls es el LSP de TypeScript que usa LazyVim v16 por defecto.
      vtsls
      typescript
      # angular-language-server es el LSP de Angular (lo pide el extra
      # lang.angular).
      angular-language-server
      typescript-language-server
      prettier
      eslint

      # Nix
      nixd
      alejandra

      # JSON / YAML
      yaml-language-server
      vscode-langservers-extracted

      # Web / general
      just
      jq

      # ─── Dependencias de LazyVim y Snacks ──────────────────────────
      # Snacks.picker necesita rg para grep y fd para el explorador.
      ripgrep
      fd

      # Interfaz de git para Snacks.lazygit.
      lazygit

      # Buscador de archivos para los pickers y Telescope.
      fzf

      # CLI de tree-sitter (lo pide el health check de LazyVim para
      # instalar grammars, aunque con Nix ya vienen compilados).
      tree-sitter

      # Snacks.explorer necesita una papelera para que "mover a la
      # papelera" no borre el fichero de forma permanente.
      trash-cli

      # Snacks.picker usa SQLite para el historial/frecency; sin esto
      # degrada a fichero plano (warning en checkhealth).
      sqlite

      # Ghostscript para previsualizar PDFs y mermaid-cli para los
      # diagramas Mermaid dentro del Markdown.
      ghostscript
      mermaid-cli

      # NOTA: para renderizar formulas LaTeX dentro del Markdown haria
      # falta tectonic o texlive. `tectonic` de nixpkgs no compila
      # (falla con AWS_LC_SYS_USE_SYSTEM sin AWS-LC instalado), asi que
      # se deja fuera. Es opcional: solo afecta a la previsualizacion de
      # LaTeX en ficheros Markdown.
    ];
  };

  # ─── Parsers de Tree-sitter ───────────────────────────────────────────
  # nvim-treesitter busca los grammars en `stdpath("data")/site/parser`
  # (ver lua/nvim-treesitter/config.lua: `install_dir`). Se enlazan alli
  # para que esten disponibles sin compilar nada en tiempo de ejecucion.
  xdg.dataFile."nvim/site/parser" = {
    source = treeSitterParsers;
  };

  # NOTA: las queries de Tree-sitter (las reglas de resaltado) vienen
  # dentro del propio plugin nvim-treesitter, en `runtime/queries/`, y
  # este plugin ya esta en el runtimepath a traves del linkFarm de
  # plugins. Por eso no hace falta enlazarlas aparte.
}
