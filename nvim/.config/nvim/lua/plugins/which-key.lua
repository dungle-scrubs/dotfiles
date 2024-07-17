return {
  "folke/which-key.nvim",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = function()
    return {
      plugins = {
        presets = {
          operators = true,
        },
      },
      defaults = {
        ["<leader>u"] = { name = "+ui" },
        ["/"] = "which_key_ignore",
      },
      show_help = false,
      show_keys = false,
    }
  end,
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.register(opts.defaults)
  end,
}
