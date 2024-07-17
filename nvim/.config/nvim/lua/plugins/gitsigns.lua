return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    current_line_blame = false,
    on_attach = function()
      local keymaps = require("config.keymaps-custom").gitsigns
      keymaps()
    end,
  },
}
