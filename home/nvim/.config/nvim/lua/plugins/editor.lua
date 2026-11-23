return {
  -- <leader>ff / <leader><space> also list dotfiles (.zshenv, .config/…).
  -- These are per-source options; a top-level `picker.hidden` means something
  -- else in snacks (which picker windows to hide), so it had no effect.
  -- Inside the picker: <a-h> toggles hidden files, <a-i> gitignored ones.
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = false, -- keep node_modules, build output etc. out
            exclude = { ".git" },
          },
        },
      },
    },
  },

  -- Send shell command output (:!cmd) to notifications instead of the cmdline.
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        {
          view = "notify",
          filter = { event = "msg_show", kind = { "shell_out", "shell_err" } },
        },
      },
    },
  },
}
