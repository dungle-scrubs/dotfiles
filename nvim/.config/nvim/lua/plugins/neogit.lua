return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = require("config.keymaps-custom").neogit.keys,
  config = function()
    require("neogit").setup({})
  end,
}
