local M = {}

M.treesitter = {
  ensure_installed = {
    "bash",
    "c",
    "c_sharp",
    "cmake",
    "cpp",
    "css",
    "csv",
    "dart",
    "diff",
    "dockerfile",
    "dot",
    "gitignore",
    "go",
    "gomod",
    "gosum",
    "graphql",
    "haskell",
    "html",
    "java",
    "javascript",
    "kotlin",
    "latex",
    "lua",
    "make",
    "markdown",
    "markdown_inline",
    "ocaml",
    "php",
    "prisma",
    "proto",
    "python",
    "query",
    "r",
    "regex",
    "rust",
    "solidity",
    "sql",
    "svelte",
    "terraform",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "xml",
    "yaml",
  },
  indent = {
    enable = true,
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "eslint-lsp",
    "typescript-language-server",
    "js-debug-adapter",
    "prettier",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",

    -- go
    "gopls",

    -- python
    "black",
    "mypy",
    "ruff",
    "pyright",

    -- rust
    "rust-analyzer",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
