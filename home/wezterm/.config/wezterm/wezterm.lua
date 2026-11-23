-- WezTerm: same behaviour on macOS and Linux (KDE).
-- Theme comes from `theme <name>` (~/.local/state/dotfiles/theme); the file is
-- watched, so switching themes reloads every window automatically.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local is_macos = wezterm.target_triple:find("darwin") ~= nil
local home = os.getenv("HOME")
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local theme_dir = state_home .. "/dotfiles/theme"

-- Theme ------------------------------------------------------------------------

-- Kanagawa palettes (from rebelot/kanagawa.nvim extras).
config.color_schemes = {
  ["Kanagawa Wave"] = {
    foreground = "#dcd7ba", background = "#1f1f28",
    cursor_bg = "#c8c093", cursor_fg = "#1f1f28", cursor_border = "#c8c093",
    selection_fg = "#c8c093", selection_bg = "#2d4f67",
    scrollbar_thumb = "#16161d", split = "#16161d",
    ansi = { "#090618", "#c34043", "#76946a", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093" },
    brights = { "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba" },
    indexed = { [16] = "#ffa066", [17] = "#ff5d62" },
  },
  ["Kanagawa Dragon"] = {
    foreground = "#c5c9c5", background = "#181616",
    cursor_bg = "#c8c093", cursor_fg = "#181616", cursor_border = "#c8c093",
    selection_fg = "#c8c093", selection_bg = "#2d4f67",
    scrollbar_thumb = "#16161d", split = "#16161d",
    ansi = { "#0d0c0c", "#c4746e", "#8a9a7b", "#c4b28a", "#8ba4b0", "#a292a3", "#8ea4a2", "#c8c093" },
    brights = { "#a6a69c", "#e46876", "#87a987", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#c5c9c5" },
    indexed = { [16] = "#b6927b", [17] = "#b98d7b" },
  },
  ["Kanagawa Lotus"] = {
    foreground = "#545464", background = "#f2ecbc",
    cursor_bg = "#43436c", cursor_fg = "#f2ecbc", cursor_border = "#43436c",
    selection_fg = "#43436c", selection_bg = "#c9cbd1",
    scrollbar_thumb = "#c7d7e0", split = "#c7d7e0",
    ansi = { "#1f1f28", "#c84053", "#6f894e", "#77713f", "#4d699b", "#b35b79", "#597b75", "#545464" },
    brights = { "#8a8980", "#d7474b", "#6e915f", "#836f4a", "#6693bf", "#624c83", "#5e857a", "#43436c" },
    indexed = { [16] = "#cc6d00", [17] = "#e82424" },
  },
}

local function read_theme()
  local f = io.open(theme_dir .. "/theme.json", "r")
  if not f then return nil end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(wezterm.json_parse, raw)
  return ok and data or nil
end

local theme = read_theme()
config.color_scheme = (theme and theme.wezterm) or "GruvboxDarkHard"
wezterm.add_to_config_reload_watch_list(theme_dir .. "/name")

-- Font -------------------------------------------------------------------------
-- JetBrainsMono Nerd Font has ligatures; calt/liga are on by default, listed
-- here so they are easy to switch off ("calt=0", "liga=0").
config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "Symbols Nerd Font Mono", -- bundled with WezTerm: icons never render as boxes
})
config.harfbuzz_features = { "calt=1", "liga=1" }
-- Points render smaller on macOS than on a typical KDE (96 dpi) screen; these
-- two sizes look about the same physically.
config.font_size = is_macos and 16.0 or 12.0

-- Window -----------------------------------------------------------------------
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
config.adjust_window_size_when_changing_font_size = false
config.max_fps = 144
config.scrollback_lines = 1000000000
config.audible_bell = "Disabled"
-- TERM stays xterm-256color: works over SSH without installing terminfo.

-- Mouse ------------------------------------------------------------------------
-- Plain click never opens links; Cmd-click (macOS) / Ctrl-click (Linux) does.
local link_mod = is_macos and "CMD" or "CTRL"
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.DisableDefaultAssignment,
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = link_mod,
    action = act.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = link_mod,
    action = act.Nop,
  },
}

return config
