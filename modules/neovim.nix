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
    # Integracion con OpenCode (ver opencodeNvim mas abajo).
    "opencode.nvim" = { repo = "nickjvandyke/opencode.nvim"; pkg = opencodeNvim; };
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

  # ─── OpenCode ─────────────────────────────────────────────────────────
  # opencode.nvim integra Neovim con el servidor/API de OpenCode.
  #
  # El paquete de nixpkgs (vimPlugins.opencode-nvim) esta en la v1.0.2,
  # que habla con la API v1 (/session, /event). Este equipo tiene
  # opencode v2.2.5, cuya API es distinta: un daemon en background y
  # eventos con forma { id, type, data }. Por eso se construye el plugin
  # desde su rama `main`, que ya soporta v2.
  #
  # El commit se fija para que la build sea reproducible.
  opencodeNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "opencode.nvim";
    version = "unstable-2026-10-30";
    src = pkgs.fetchgit {
      url = "https://github.com/nickjvandyke/opencode.nvim.git";
      rev = "4851ae503585dc5142ad66a98e8952a74e1f7b3a";
      hash = "sha256-Qhn8hGQ/S6SCV0GxsrS8nAPSq0ndwMNaEYhOw0Mv/Pc=";
    };
    doCheck = false;
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

      -- ─── OpenCode ────────────────────────────────────────────────────
      -- El setup va AQUI (y no en el `config` del spec) porque Home
      -- Manager deja los plugins en `pack/hm/start/`, que Neovim carga
      -- antes de ejecutar el init.lua. Al estar ya en el runtimepath,
      -- lazy.nvim no ejecuta su `config`, asi que el wrapper de `ask` y
      -- el daemon por proyecto nunca se configuraban.
      --
      -- ─── Por que un daemon por proyecto ──────────────────────────────
      -- OpenCode v2 scopea las sesiones al DIRECTORIO DE TRABAJO del
      -- daemon (no a los headers HTTP ni al query `?directory=`). El
      -- servicio global (`opencode serve --service`) arranca con el cwd
      -- desde el que se lanzo, asi que si Neovim se abre en un
      -- subdirectorio no encuentra sesiones para ese proyecto.
      --
      -- Por eso aqui se lanza un daemon por directorio (con su cwd) en
      -- un puerto derivado del path, y se lee su password del log que
      -- imprime OpenCode al arrancar.
      local opencode_state = {
        servers = {},        -- cwd -> server
        password = nil,      -- password del daemon del proyecto actual
        url = nil,           -- url del daemon del proyecto actual
      }

      local function opencode_state_dir()
        if vim.env.XDG_STATE_HOME and vim.env.XDG_STATE_HOME ~= "" then
          return vim.env.XDG_STATE_HOME .. "/opencode"
        end
        return (vim.uv.os_homedir() or vim.env.HOME or "") .. "/.local/state/opencode"
      end

      -- Puerto estable por proyecto (4096 + hash del path).
      local function port_for(cwd)
        local hash = 0
        for i = 1, #cwd do
          hash = (hash * 31 + cwd:byte(i)) % 400
        end
        return 4096 + hash
      end

      -- Arranca (si hace falta) el daemon del proyecto y devuelve su url.
      -- Es lazy: solo se llama cuando opencode.nvim va a conectar.
      local function ensure_project_server(cwd)
        if opencode_state.url and opencode_state.cwd == cwd then
          return opencode_state.url
        end

        local port = port_for(cwd)
        local url = "http://127.0.0.1:" .. port
        local state_dir = opencode_state_dir()
        local logfile = state_dir .. "/nvim-server-" .. port .. ".log"

        -- ¿Ya hay un daemon escuchando?
        local probe = vim.fn.system({
          "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", url .. "/api/info",
        })

        if probe ~= "200" and probe ~= "401" then
          -- Arrancarlo con el cwd del proyecto. Se usa `sh -c` para poder
          -- redirigir la salida a un fichero: con `detach = true` Neovim
          -- no entrega el stdout del job, y la password solo se imprime
          -- por ahi. `detach` hace falta porque si no, Neovim mata el
          -- daemon al salir.
          vim.fn.jobstart({
            "sh",
            "-c",
            string.format(
              "opencode serve --port %d > %s 2>&1",
              port,
              vim.fn.shellescape(logfile)
            ),
          }, {
            cwd = cwd,
            detach = true,
          })

          -- Esperar a que publique su password.
          for _ = 1, 80 do
            vim.wait(100, function()
              return false
            end, 10)
            if vim.fn.filereadable(logfile) == 1 then
              local ok, lines = pcall(vim.fn.readfile, logfile)
              if ok and lines and #lines > 0 then
                -- OpenCode imprime "server password <password>".
                local pw = table.concat(lines, "\n"):match("server password (%S+)")
                if pw then
                  opencode_state.password = pw
                  break
                end
              end
            end
          end
        end

        -- Si el daemon ya existia (de una sesion anterior), leer su
        -- password del registro que escribimos.
        if not opencode_state.password then
          local registration = state_dir .. "/service-nvim-" .. port .. ".json"
          if vim.fn.filereadable(registration) == 1 then
            local ok, lines = pcall(vim.fn.readfile, registration)
            if ok and lines and #lines > 0 then
              local decoded_ok, decoded = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
              if decoded_ok and type(decoded) == "table" then
                opencode_state.password = decoded.password
              end
            end
          end
        end

        -- Publicar el daemon para que opencode.nvim lo descubra (asi
        -- puede leer su password).
        if opencode_state.password then
          vim.fn.writefile({
            vim.json.encode({
              id = "nvim-" .. port,
              version = "2.2.5",
              url = url,
              password = opencode_state.password,
            }),
          }, state_dir .. "/service-nvim-" .. port .. ".json")
        end

        opencode_state.cwd = cwd
        opencode_state.url = url
        return url
      end

      -- Configuracion de opencode.nvim.
      --
      -- OJO: `vim.g` no admite funciones en Neovim, asi que la URL
      -- dinamica se aplica sobre `require("opencode.config").opts`, que
      -- es lo que consulta el plugin (ver lua/opencode/config.lua).
      local function apply_opencode_config()
        vim.g.opencode_opts = {
          server = {
            -- Lanzar el daemon de OpenCode en un terminal de Snacks.
            --
            -- Se pasa el directorio actual porque OpenCode v2 scopea las
            -- sesiones al cwd del daemon.
            start = function()
              require("snacks.terminal").open(
                "opencode " .. vim.fn.shellescape(vim.fn.getcwd()),
                { win = { position = "right", enter = false }, cwd = vim.fn.getcwd() }
              )
            end,
          },
          events = {
            enabled = true,
            -- Recargar los buffers cuando OpenCode edita un fichero.
            reload = { enabled = true },
          },
        }

        -- Recargar el modulo de config: calcula sus defaults al
        -- cargarse y hay que reponer la URL dinamica.
        package.loaded["opencode.config"] = nil
        local opts = require("opencode.config").opts

        -- La URL se resuelve al conectar. Al hacerlo, `ensure_project_server`
        -- deja la password del daemon en `opencode_state`, asi que se
        -- propaga a la config justo despues (si no, `server.new(url)`
        -- se crearia sin credenciales).
        opts.server.url = function()
          local cwd = vim.fn.getcwd()
          if not cwd or cwd == "" then
            return nil
          end
          local url = ensure_project_server(cwd)
          if opencode_state.password then
            opts.server.password = opencode_state.password
            vim.env.OPENCODE_SERVER_PASSWORD = opencode_state.password
          end
          return url
        end

        if opencode_state.password then
          opts.server.password = opencode_state.password
          vim.env.OPENCODE_SERVER_PASSWORD = opencode_state.password
        end
      end

      -- Si el directorio actual no tiene sesion, crearla. La API v2 la
      -- crea en el cwd del daemon, que en este caso es el del proyecto.
      --
      -- OJO: `server.new(url, ...)` devuelve una PROMESA que resuelve al
      -- servidor, no el servidor directamente.

      -- Crear la sesion del directorio actual en segundo plano, para
      -- que `ask`/`prompt` la encuentren sin tener que esperar.
      --
      -- NO se envuelven `ask` ni `prompt`: esos esperan de forma
      -- asincrona (promesas con curl), y un `vim.wait` dentro bloquearia
      -- el event loop y el prompt no se abriria nunca.
      local function ensure_session_async()
        local cwd = vim.fn.getcwd()
        if not cwd or cwd == "" then
          return
        end

        local url = ensure_project_server(cwd)
        if not url then
          return
        end

        local server
        local resolved = false
        require("opencode.server").new(url, {
          username = "opencode",
          password = opencode_state.password,
        }):next(function(s)
          server = s
          resolved = true
        end, function()
          resolved = true
        end)

        -- Se espera de forma no bloqueante: se comprueba en un timer.
        local timer = vim.uv.new_timer()
        timer:start(100, 100, vim.schedule_wrap(function()
          if resolved and server then
            timer:stop()
            timer:close()

            -- ¿Ya hay sesion para este directorio?
            server:get_sessions():next(function(sessions)
              for _, session in ipairs(sessions or {}) do
                if not (session.time and session.time.archived) then
                  return
                end
              end
              -- No hay: crearla.
              server:request("/api/session", "POST", {}):next(function(response)
                if response and response.data then
                  vim.notify("OpenCode: sesion creada para " .. cwd, vim.log.levels.INFO)
                end
              end, function() end)
            end, function() end)
          end
        end))
      end

      -- Aplicar la configuracion (URL dinamica + password).
      apply_opencode_config()

      -- Asegurar la sesion del directorio actual, y crear una nueva cada
      -- vez que se cambie de directorio.
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
          ensure_session_async()
        end,
      })
      vim.schedule(function()
        ensure_session_async()
      end)

      -- Neovim debe recargar los ficheros que OpenCode edita.
      vim.o.autoread = true

      -- ─── Keymaps de OpenCode ──────────────────────────────────────────
      -- `oa` pregunta, `os` abre el menu de prompts y comandos, `ov`
      -- manda la seleccion visual y `oo` la linea.
      --
      -- Se registran en `User LazyDone` porque LazyVim define el leader
      -- (`vim.g.mapleader = " "`) en su options.lua, que se carga DESPUES
      -- de este bloque. Si se registraran aqui, `<leader>` se resolveria
      -- con el valor por defecto (`\\`) y las teclas no responderian.
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyDone",
        once = true,
        callback = function()
          vim.keymap.set({ "n", "x" }, "<leader>oa", function()
            require("opencode").ask("@this: ")
          end, { desc = "Preguntar a OpenCode" })

          vim.keymap.set({ "n", "x" }, "<leader>os", function()
            require("opencode").select()
          end, { desc = "Menu de OpenCode" })

          vim.keymap.set({ "n", "x" }, "<leader>ov", function()
            return require("opencode").operator("@this")
          end, { expr = true, desc = "Mandar la seleccion a OpenCode" })

          vim.keymap.set("n", "<leader>oo", function()
            return require("opencode").operator("@this") .. "_"
          end, { expr = true, desc = "Mandar la linea a OpenCode" })
        end,
      })


      -- LazyVim con todos los plugins servidos desde nixpkgs.
      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins", dev = true, pin = true },

          -- Snacks.explorer: explorador de archivos nativo de LazyVim
          -- v16. Sustituye al extra util.project, que requeria telescope
          -- o fzf-lua para funcionar.
          --
          -- El bloque de `input` y `picker` es la integracion que
          -- opencode.nvim necesita para que `ask()` y `select()` usen
          -- los prompts de Snacks (con completions via LSP interno).
          {
            "folke/snacks.nvim",
            opts = {
              explorer = { enabled = true },
              input = { enabled = true },
              picker = {
                enabled = true,
                win = {
                  input = {
                    keys = {
                      ["<a-o>"] = { "opencode_send", mode = { "n", "i" } },
                    },
                  },
                },
                actions = {
                  opencode_send = function(picker)
                    local items = vim.tbl_map(function(item)
                      return item.file
                        and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
                        or item.text
                    end, picker:selected({ fallback = true }))
                    require("opencode").prompt(table.concat(items, ", ") .. " ")
                  end,
                },
              },
            },
          },

          -- ─── OpenCode ───────────────────────────────────────────────────
          -- Integracion con el servidor/API de OpenCode v2.
          --
          -- El servidor se lanza en un terminal de Snacks (derecha) y el
          -- plugin se conecta a el. Los eventos del servidor se reenvian
          -- como autocmds `User OpencodeEvent:*`.
          {
            "nickjvandyke/opencode.nvim",
            -- El plugin se configura desde el init.lua (bloque de OpenCode
            -- de arriba), porque Home Manager deja los plugins en
            -- `pack/hm/start/` y lazy.nvim no ejecuta su `config` cuando
            -- ya estan en el runtimepath.
          },

          -- ─── Terminal de OpenCode ───────────────────────────────────────
          -- Tecla para mostrar/ocultar el terminal donde corre OpenCode.
          -- Se usa `<C-.>` y no `<leader>t` porque Neovim anade un
          -- retardo al leader cuando hay una mapping con <leader>.
          {
            "folke/snacks.nvim",
            opts = {
              terminal = { enabled = true },
            },
            -- La forma de lazy.nvim es { lhs, rhs, opts }. El modo va
            -- en `opts.mode`, no como primer elemento del array (eso
            -- hace que lazy.nvim intente leer una tabla donde espera
            -- un string y falle al montar los handlers).
            keys = {
              {
                "<C-.>",
                function()
                  require("snacks.terminal").toggle("opencode", {
                    win = { position = "right", enter = false },
                  })
                end,
                { mode = { "n", "t" }, desc = "Terminal de OpenCode" },
              },
            },
          },

          -- ─── Statusline de OpenCode ─────────────────────────────────────
          -- Muestra el servidor conectado y su estado.
          {
            "nvim-lualine/lualine.nvim",
            opts = {
              sections = {
                lualine_z = {
                  { require("opencode").statusline },
                },
              },
            },
          },

          -- ─── Mason desactivado ───────────────────────────────────────
          -- En Nix todas las herramientas (LSPs, formatters, linters)
          -- vienen del nix store. Mason no lo sabe y trata de instalar
          -- sus propias copias, lo que falla (sin `unzip`, `cargo`,
          -- `luarocks`...) y ensucia el home.
          --
          -- Por eso se vacian sus listas de `ensure_installed` y se
          -- desactivan los servidores que Mason gestionaria, de modo
          -- que nvim-lspconfig los activa directamente con el binario
          -- del PATH.
          {
            "mason-org/mason.nvim",
            opts = {
              ensure_installed = {},
              install_root_dir = vim.fn.stdpath("data") .. "/mason",
            },
            config = function(_, opts)
              require("mason").setup(opts)
            end,
          },
          {
            "mason-org/mason-lspconfig.nvim",
            opts = {
              ensure_installed = {},
            },
          },

          -- Los servidores LSP se configuran con `mason = false` para
          -- que nvim-lspconfig los active directamente con el binario
          -- del PATH, sin que Mason tenga que instalar nada.
          {
            "neovim/nvim-lspconfig",
            opts = {
              servers = {
                gopls = { mason = false },
                angularls = { mason = false },
                nil_ls = { mason = false },
                jsonls = { mason = false },
                yamlls = { mason = false },
                marksman = { mason = false },
                tailwindcss = { mason = false },
                dockerls = { mason = false },
                vtsls = { mason = false },
                ts_ls = { mason = false },
                tsserver = { mason = false },
                tsc = { mason = false },
              },
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
      stylua
      shfmt

      # JSON / YAML
      yaml-language-server
      vscode-langservers-extracted

      # Linters de Markdown y Docker (los instalaba Mason, ahora van
      # desde nixpkgs).
      markdownlint-cli2
      markdown-toc
      hadolint

      # Web / general
      just
      jq

      # Cliente de OpenCode: el plugin abre un terminal con el daemon y
      # se conecta a su API.
      opencode

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
