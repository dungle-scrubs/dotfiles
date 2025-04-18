return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    local smart_splits = require("smart-splits")
    smart_splits.setup({
      -- at_edge = "stop",
    })
    -- vim.notify("🌶️  smart-split.lua:9 > stop: " .. vim.inspect("stop"))
    --
    -- map("n", "<C-h>", function()
    --   smart_splits.move_cursor_left()
    -- end)
    -- map("n", "<C-j>", smart_splits.move_cursor_down)
    -- map("n", "<C-k>", smart_splits.move_cursor_up)
    -- map("n", "<C-l>", smart_splits.move_cursor_right)
  end,
}
