return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = function()
    return {}
  end,
  opts = function(_, opts)
    local keymaps = require("config.keymaps-custom")
    opts.window.mappings = keymaps.neotree.mappings
    opts.filesystem.hijack_netrw_behavior = "open_current"
    opts.filesystem.window = {}
    opts.filesystem.window.mappings = {}
    opts.filesystem.window.mappings["<cr>"] = "open_and_close_tree"
    opts.filesystem.commands = {}
    opts.filesystem.commands.open_and_close_tree = function(state)
      require("neo-tree.sources.filesystem.commands").open(state)
      vim.schedule(function()
        vim.cmd([[Neotree close]])
      end)
    end
    return opts
  end,
}
