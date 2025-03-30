local wezterm = require("wezterm")

local config = wezterm.config_builder()
-- local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

config.font = wezterm.font_with_fallback({ "MonaspiceKr Nerd Font", "Monaspace Krypton" })
config.font_size = 13
config.color_scheme = "Tokyo Night"

config.default_cursor_style = "SteadyUnderline"

-- Window
config.window_decorations = "RESIZE"
-- config.window_decorations = "RESIZE | TITLE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30

config.command_palette_bg_color = "#1A1B26"
config.command_palette_fg_color = "#C0CAF5"

-- Tab bar
--
-- This errors out, apply tab defaults manually
-- tabline.apply_to_config(config)
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.show_tab_index_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

tabline.setup({
	options = {
		icons_enabled = true,
		theme = "tokyonight_moon",
		section_separators = {
			left = "",
			right = "", -- Removed all separators to reduce padding
		},
		component_separators = {
			left = "",
			right = "", -- Removed internal separators
		},
		tab_separators = {
			left = "",
			right = "", -- Made tab separators invisible to reduce spacing
		},
	},
	sections = {
		tabline_a = { "hostname", padding = 1 },
		tabline_b = { "" },
		tabline_c = { "" },
		tab_active = {
			{ "index", padding = 1 },
			-- { "parent", padding =
			{ "/", padding = 1 },
			{ "cwd", padding = 1 },
			{ "zoomed", padding = 1 },
		},
		tab_inactive = {
			{ "index", padding = 1 },
			{ "process", padding = 1 },
		},
		tabline_x = {
			{ "ram", padding = 1 },
			{ "cpu", padding = 1 },
		},
		tabline_y = {
			{ "datetime", padding = 1 },
			{ "battery", padding = 1 },
		},
		tabline_z = { "" },
	},
	extensions = {},
})

config.max_fps = 120

return config
