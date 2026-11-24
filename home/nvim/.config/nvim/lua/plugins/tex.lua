-- LaTeX on top of LazyVim's lang.tex extra (vimtex + texlab).
--   build:   vimtex runs latexmk (defaults in ~/.config/latexmk/latexmkrc)
--   viewer:  Skim on macOS, zathura on Linux; SyncTeX both ways
--   lint:    chktex through texlab;  format: latexindent through texlab
--
-- In a .tex file: <localleader>ll compile (continuous), <localleader>lv jump to
-- the PDF, Shift-Cmd-click (Skim) / Ctrl-click (zathura) jumps back here.

local is_mac = vim.fn.has("mac") == 1
local aux_dir = ".build" -- same as $aux_dir in latexmkrc

return {
  {
    "lervag/vimtex",
    init = function()
      if is_mac then
        vim.g.vimtex_view_method = "skim"
        vim.g.vimtex_view_skim_sync = 1 -- move the PDF to the cursor after each build
        vim.g.vimtex_view_skim_activate = 0 -- keep focus in the terminal
      else
        -- KDE Plasma runs on Wayland, where vimtex's xdotool-based zathura mode
        -- cannot work; zathura_simple keeps forward and inverse search.
        vim.g.vimtex_view_method = vim.env.WAYLAND_DISPLAY and "zathura_simple" or "zathura"
      end
      vim.g.vimtex_compiler_latexmk = {
        aux_dir = aux_dir,
        options = { "-verbose", "-file-line-error", "-synctex=1", "-interaction=nonstopmode" },
      }
      vim.g.vimtex_quickfix_open_on_warning = 0 -- errors open the list, warnings don't
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              build = { auxDirectory = aux_dir },
              chktex = { onOpenAndSave = true },
            },
          },
        },
      },
    },
  },
}
