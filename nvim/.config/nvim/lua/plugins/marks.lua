return {
  "chentoast/marks.nvim",
  event = "BufReadPre",
  config = function()
    require("marks").setup({
      default_mappings = true,
    })
  end,
}
