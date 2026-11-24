-- jdtls (the Java language server) needs Java 25 or newer to run, whatever JDK a
-- project builds with. Start the server with mise's Temurin 25 (installed by
-- the bootstrap) while the default `java` stays Temurin 21.

local function java25()
  local out = vim.fn.system({ "mise", "where", "java@temurin-25" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local java = vim.trim(out) .. "/bin/java"
  return vim.fn.executable(java) == 1 and java or nil
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local java = java25()
      if java then
        table.insert(opts.cmd, "--java-executable=" .. java)
      end
    end,
  },
}
