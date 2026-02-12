local wezterm = require("wezterm")

local config = {
  color_scheme = "Catppuccin Mocha",
  window_background_opacity = 0.95,
  enable_tab_bar = true,
  window_decorations = "RESIZE",
  font = wezterm.font("MesloLGS Nerd Font"),
  native_macos_fullscreen_mode = true,
  keys = {
    {
      key = "n",
      mods = "SHIFT|CTRL",
      action = wezterm.action.ToggleFullScreen,
    },
  },
}

return config
