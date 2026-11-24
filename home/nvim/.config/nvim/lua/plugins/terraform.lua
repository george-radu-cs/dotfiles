-- Terraform files use OpenTofu (open source, installed by mise) instead of
-- HashiCorp's BSL-licensed terraform CLI: `tofu validate` for linting and
-- `tofu fmt` for formatting. terraform-ls is pointed at tofu in lsp.lua.
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        terraform = { "tofu" },
        tf = { "tofu" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        terraform = { "tofu_fmt" },
        tf = { "tofu_fmt" },
        ["terraform-vars"] = { "tofu_fmt" },
      },
    },
  },
}
