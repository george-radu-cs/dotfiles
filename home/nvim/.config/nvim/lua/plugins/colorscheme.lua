-- Colourscheme follows the shared dotfiles theme (`theme <name>` in the shell).
-- Reads ~/.local/state/dotfiles/theme/theme.json at startup and again whenever
-- nvim regains focus, so a theme switch reaches running nvim instances too.

local state = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")) .. "/dotfiles/theme/theme.json"

local function read_theme()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state), "\n"))
  end)
  if ok and type(data) == "table" and data.nvim then
    return data
  end
  return { nvim = "gruvbox", appearance = "dark" }
end

local current

local function apply()
  local t = read_theme()
  if current == t.nvim .. t.appearance then
    return
  end
  current = t.nvim .. t.appearance
  vim.o.background = t.appearance == "light" and "light" or "dark"
  local ok = pcall(vim.cmd.colorscheme, t.nvim)
  if not ok then
    vim.cmd.colorscheme("gruvbox")
  end
end

vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("dotfiles_theme", { clear = true }),
  -- nested: lazy.nvim loads colourscheme plugins from a ColorSchemePre autocmd,
  -- which would not fire from inside this one otherwise.
  nested = true,
  callback = apply,
})

return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = { contrast = "hard" },
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      compile = false,
      background = { dark = "wave", light = "lotus" },
    },
  },
  -- tokyonight and catppuccin ship with LazyVim, available via <leader>uC.

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = apply },
  },
}
