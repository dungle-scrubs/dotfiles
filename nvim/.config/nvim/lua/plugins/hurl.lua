return {
  "jellydn/hurl.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  ft = "hurl",
  opts = {
    -- Show debugging info
    debug = false,
    -- Show notification on run
    show_notification = false,
    -- Show response in popup or split
    mode = "split",
    -- Default formatter
    formatters = {
      json = { "jq" }, -- Make sure you have install jq in your system, e.g: brew install jq
      html = {
        "prettier", -- Make sure you have install prettier in your system, e.g: npm install -g prettier
        "--parser",
        "html",
      },
    },
  },
}
