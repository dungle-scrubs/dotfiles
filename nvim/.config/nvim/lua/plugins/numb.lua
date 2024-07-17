return {
  "nacro90/numb.nvim",
  event = "BufReadPre",
  config = function()
    require("numb").setup({
      show_numbers = true,
      show_cursorline = true,
      number_only = false,
      centered_peeking = true,
    })
  end,
}
