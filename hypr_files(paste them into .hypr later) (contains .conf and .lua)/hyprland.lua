-- Hyprland Configuration (Lua)
-- Converted from hyprland.conf — all bugs from previous .lua.bak fixed

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = "1",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local snipshot    = ".config/hypr/scripts/snipshot.fish"
local annotate    = ".config/hypr/scripts/annotate.fish"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("thunar --daemon")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("mkdir -p ~/.cache/awww")
    hl.exec_cmd("awww-daemon &")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XWAYLAND_HYPRLAND_NO_PAUSE", "1")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = { top = 7, right = 7, bottom = 7, left = 7 },
        border_size = 0,
        col = {
            active_border   = { colors = { "rgba(ffffffcc)", "rgba(1a1a1acc)" }, angle = 45 },
            inactive_border = "rgba(ff3c3ccc)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
        blur = {
            enabled  = true,
            size     = 8,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        enable_anr_dialog       = false,
    },

    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll          = true,
            tap_to_click            = true,
            disable_while_typing    = false,
            scroll_factor           = 1.0,
            middle_button_emulation = true,
        },
    },


    xwayland = {
        force_zero_scaling = true,
    },
})

-- Gestures
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


--------------------------
---- DEVICE OVERRIDES ----
--------------------------

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


----------------------------
---- BEZIERS & ANIM ----
----------------------------

-- Cinematic bezier curves
hl.curve("overshot",  { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn",  { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- Animation definitions
hl.animation({ leaf = "windows",     enabled = true, speed = 5,  bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4,  bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,  bezier = "default" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 10, bezier = "smoothIn" })
hl.animation({ leaf = "fadeDim",     enabled = true, speed = 10, bezier = "smoothIn" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Transparency & Blur Rules
hl.window_rule({
    match   = { class = "^(foot)$" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    match   = { class = "^(thunar)$" },
    opacity = "0.90 0.80",
})

hl.window_rule({
    match   = { class = "^(vesktop)$" },
    opacity = "0.85 0.75",
})

hl.window_rule({
    match   = { class = "^(discord)$" },
    opacity = "0.85 0.75",
})

-- Other rules
hl.window_rule({
    match  = { class = "^(.*com.network.manager.*)$" },
    float  = true,
    center = true,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Core binds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("touch /tmp/qs_toggle_launcher"))
hl.bind(mainMod .. " + P", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("fish .config/hypr/scripts/sniprec.fish"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("fish .config/hypr/scripts/snipocr.fish"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("fish .config/hypr/scripts/reload.fish"))
hl.bind(mainMod .. " + A", hl.dsp.window.fullscreen({ type = 0 }))

-- Utility binds
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("fish " .. snipshot))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("fish " .. annotate))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))

-- Quickshell Alt-Tab wheel (press triggers hold file; release cleans up)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("sh -c 'touch /tmp/qs_wheel_holding; sleep 0.15; if [ -f /tmp/qs_wheel_holding ]; then touch /tmp/qs_wheel_open; fi'"))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("rm -f /tmp/qs_wheel_holding /tmp/qs_wheel_open"), { release = true, transparent = true })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10  -- maps workspace 10 → key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ -l 1"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media keys (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
