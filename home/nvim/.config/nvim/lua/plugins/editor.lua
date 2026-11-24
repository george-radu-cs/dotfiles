return {
  -- Dotfiles (.zshenv, .config/…) are visible in <leader>ff / <leader><space>
  -- and in the file tree (<leader>e). These are per-source options; a top-level
  -- `picker.hidden` means something else in snacks (which picker windows to
  -- hide). Toggle in the picker: <a-h> hidden, <a-i> gitignored; in the tree: H, I.
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
          explorer = {
            hidden = true,
            ignored = false,
            exclude = { ".git", ".DS_Store" },
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
