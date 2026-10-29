-- Configuracion de Hyprland 0.55 en Lua.
-- Traduccion directa del antiguo hyprland.conf.
-- Referencia: https://wiki.hypr.land/Configuring/Start/

local colors = require("colors")

local terminal    = "kitty"
local fileManager = "nautilus"

local mainMod = "SUPER"
local seccMod = "ALT"


--------------------
---- MONITORES ----
--------------------

hl.monitor({
    output   = "DP-1",
    mode     = "1920x1080@164",
    position = "300x1080",
    scale    = "1",
    vrr      = 1,
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "2560x1080@60",
    position = "0x0",
    scale    = "1",
})


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("sh ~/.config/hypr/ipc-compat.sh")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprpolkitagent")
    hl.exec_cmd("hyprpanel")
    hl.exec_cmd("ulauncher --hide-window --no-window-shadow")
end)


-------------------------------
---- VARIABLES DE ENTORNO ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_THEME", "Adwaita")

-- VirtualBox con X11 (xcb) en vez de Wayland: evita la pantalla negra
hl.env("QT_QPA_PLATFORM", "xcb")


---------------------
---- ASPECTO ----
---------------------

hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,

        border_size = 2,

        col = {
            active_border   = colors.lavender,
            inactive_border = colors.surface2,
        },

        resize_on_border = true,
        allow_tearing    = true,

        layout = "dwindle",
    },

    decoration = {
        rounding = 3,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        blur = {
            enabled = false,
        },
    },
})

-- Curvas y animaciones
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

hl.config({
    animations = {
        enabled = true,
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },
})


-------------
---- INPUT ----
-------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- ATAJOS ----
---------------------

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ulauncher-toggle"))
hl.bind(seccMod .. " + B", hl.dsp.exec_cmd("brave"))
hl.bind(seccMod .. " + D", hl.dsp.exec_cmd("vesktop"))
hl.bind(seccMod .. " + S", hl.dsp.exec_cmd("steam"))
hl.bind(seccMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(seccMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("pear-desktop"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(seccMod .. " + W", hl.dsp.window.kill())
hl.bind(seccMod .. " + A", hl.dsp.exec_cmd("hyprpanel toggleWindow settings-dialog"))
hl.bind(seccMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("rotatesplit"))

-- Mover el foco con las flechas
hl.bind(seccMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(seccMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(seccMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(seccMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Cambiar de workspace y mover ventanas a otro workspace
for i = 1, 10 do
    local key = i % 10
    hl.bind(seccMod .. " + SHIFT + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(seccMod .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mover y redimensionar ventanas con SUPER + clic
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })


----------------------------------
---- VENTANAS Y WORKSPACES ----
----------------------------------

hl.window_rule({
    name  = "suppress-maximize",
    match = { class = "^.*$" },

    suppress_event = "maximize",
})

-- VirtualBox: forzar X11 para evitar pantalla negra en fullscreen
hl.window_rule({
    name  = "virtualbox-opaque",
    match = { class = "^(virtualbox|VirtualBox)$" },

    opacity = "1.0",
})

-- CS2: forzar workspace 2 y habilitar tearing
hl.window_rule({
    name  = "cs2-workspace-2",
    match = { class = "^(cs2)$" },

    workspace = 2,
})

hl.window_rule({
    name  = "ulauncher-limpio",
    match = { class = "^(ulauncher)$" },

    border_size = 0,
    no_shadow   = true,
    animation   = "none",
})

-- Picture-in-Picture: flotante y siempre encima
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture)$" },

    float = true,
    pin   = true,
    size  = { 640, 360 },
})
