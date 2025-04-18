return {
  "stevearc/oil.nvim",
  vscode = false,
  opts = {},
  keys = {
    { "<leader>kk", ":lua require('oil.actions').parent.callback()<cr>", desc = "Oil" },
  },
  event = "VeryLazy",
  config = function()
    require("oil").setup({
      default_file_explorer = false,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      experimental_watch_for_changes = true,
      show_hidden = true,
      use_default_keymaps = false,
      keymaps = {
        ["<CR>"] = "actions.select",
        ["<bs>"] = "actions.parent",
        ["H"] = "actions.toggle_hidden",
        ["<esc>"] = "actions.close",
      },
      view_options = {
        show_hidden = true,
      },

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
