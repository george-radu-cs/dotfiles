-- Obsidian vaults in Neovim: [[links]], backlinks, daily notes, tags, search.
-- Works on the same files as the Obsidian app. Every folder under ~/Obsidian
-- with a .obsidian directory is a workspace; the plugin only loads for notes
-- inside one.
--
-- Keys (<leader>o): o find note, s search, n new, d today's note, b backlinks,
-- l links in note, t tags, w switch vault. In a note, <CR> follows a link.

local root = vim.fn.expand("~/Obsidian")

local function vaults()
  local found = {}
  for _, dir in ipairs(vim.fn.glob(root .. "/*/.obsidian", false, true)) do
    local path = vim.fn.fnamemodify(dir, ":h")
    table.insert(found, { name = vim.fn.fnamemodify(path, ":t"), path = path })
  end
  return found
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    event = { "BufReadPre " .. root .. "/*.md", "BufNewFile " .. root .. "/*.md" },
    cmd = "Obsidian",
    cond = function()
      return #vaults() > 0
    end,
    keys = {
      { "<leader>o", "", desc = "+obsidian" },
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search notes" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Today's note" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links in note" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "Switch vault" },
    },
    opts = function()
      return {
        workspaces = vaults(),
        legacy_commands = false, -- :Obsidian <subcommand> only
        picker = { name = "snacks.picker" }, -- LazyVim's picker
        -- Name new notes after their title, like the Obsidian app does.
        note_id_func = require("obsidian.builtin").title_id,
        new_notes_location = "current_dir",
        daily_notes = { folder = "Journal" },
        attachments = { folder = "_content_media" },
        -- LazyVim's markdown extra already renders Markdown (render-markdown.nvim).
        ui = { enable = false },
      }
    end,
  },
}
