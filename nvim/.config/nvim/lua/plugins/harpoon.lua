return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
      sync_ui_on_close = true,
    },
  },
  keys = function()
    require("config.keymaps-custom").harpoon()
    return {}
  end,
}
