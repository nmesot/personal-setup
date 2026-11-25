-- WezTerm config: SF Mono 15, dark theme, animated pixel cat top right.
-- Lives in ~/workspace/personal-setup/wezterm/, symlinked to ~/.wezterm.lua.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local here = wezterm.home_dir .. '/workspace/personal-setup/wezterm'

-- Font: same SF Mono as Terminal.app (borrowed from its bundle), size 15.
config.font_dirs = { '/System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts' }
config.font = wezterm.font_with_fallback { 'SF Mono', 'JetBrains Mono' }
config.font_size = 15.0

-- Colors.
config.color_scheme = 'Catppuccin Mocha'
local bg = '#1e1e2e' -- Catppuccin Mocha background

-- Window.
config.initial_cols = 120
config.initial_rows = 34
config.window_padding = { left = 12, right = 12, top = 10, bottom = 8 }
config.hide_tab_bar_if_only_one_tab = true

-- Background: solid color, plus the cat sitting in the top-right corner.
-- The GIF animates while the window has focus.
config.background = {
  { source = { Color = bg }, width = '100%', height = '100%' },
  {
    source = { File = { path = here .. '/cat.gif', speed = 1.0 } },
    width = 114 * 2,
    height = 108 * 2,
    horizontal_align = 'Right',
    vertical_align = 'Top',
    horizontal_offset = -16,
    vertical_offset = 12,
    repeat_x = 'NoRepeat',
    repeat_y = 'NoRepeat',
    opacity = 0.9,
  },
}

return config
