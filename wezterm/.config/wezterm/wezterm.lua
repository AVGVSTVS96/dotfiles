local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font = wezterm.font("Monaspace Krypton")
config.font_size = 13
config.color_scheme = "Tokyo Night"

config.default_cursor_style = "SteadyUnderline"

config.enable_tab_bar = false
config.window_decorations = "RESIZE | TITLE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30

config.command_palette_bg_color = "#1A1B26"
config.command_palette_fg_color = "#C0CAF5"

config.max_fps = 120

return config
