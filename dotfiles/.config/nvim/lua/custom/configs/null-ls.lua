local null_ls = require "null-ls"

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local b = null_ls.builtins

local sources = {
  -- webdev stuff
  b.diagnostics.eslint,
  b.formatting.prettier,

  -- Lua
  b.formatting.stylua,

  -- cpp
  b.formatting.clang_format,

  -- go
  b.formatting.gofumpt,
  b.formatting.goimports_reviser,
  b.formatting.golines,

  -- python
  b.formatting.black,
  b.diagnostics.mypy,
  b.diagnostics.ruff,
}

-- autoformat on save
null_ls.setup {
  debug = true,
  sources = sources,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
}
