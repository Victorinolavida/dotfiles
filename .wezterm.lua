-- pull in the wezterm API
local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 16
-- config.color_scheme = "Batman"
config.color_scheme = "catppuccin-frappe"
config.font = wezterm.font("JetBrains Mono")
config.window_background_opacity = 0.96

return config
