-- Language server overrides on top of LazyVim's language extras.

-- OpenTofu (open-source Terraform, installed by mise) for terraform-ls.
local tofu = vim.fn.exepath("tofu")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Kotlin: fwcd's kotlin-language-server is archived and crashes with
        -- current Kotlin; use JetBrains' official server (kotlin-lsp) instead.
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {},

        -- Twig: twiggy needs a project folder (composer.json or .git) and errors
        -- on loose files; only start it when one is found.
        twiggy_language_server = { workspace_required = true },

        -- Terraform: terraform-ls needs a terraform binary for validation and
        -- formatting; point it at OpenTofu instead of HashiCorp's BSL-licensed CLI.
        terraformls = tofu ~= "" and { init_options = { terraform = { path = tofu } } } or {},
      },
    },
  },
}
