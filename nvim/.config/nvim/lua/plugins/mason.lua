return {
  "williamboman/mason.nvim",
  keys = function()
    return {}
  end,
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "luacheck",
      "shellcheck",
      "shfmt",
      "css-lsp",
      "css-variables-language-server",
      "html-lsp",
    })
  end,
}
