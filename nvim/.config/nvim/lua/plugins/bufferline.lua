return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  enabled = true,
  keys = function()
    return {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    }
  end,
}
