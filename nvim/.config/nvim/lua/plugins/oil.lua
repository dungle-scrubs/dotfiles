return {
  "stevearc/oil.nvim",
  opts = {},
  event = "VeryLazy",
  config = function()
    require("oil").setup({
      default_file_explorer = false,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      experimental_watch_for_changes = true,
      show_hidden = true,
      use_default_keymaps = false,
      keymaps = require("config.keymaps-custom").oil,

      -- Window-local options to use for oil buffers
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
    })
  end,
}
