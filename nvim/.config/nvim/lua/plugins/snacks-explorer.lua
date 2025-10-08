local excluded = {
  -- MacOS
  ".DS_Store",
}

return {
  desc = "Snacks File Explorer",
  recommended = true,
  "folke/snacks.nvim",
  keys = {
    { "<leader>E", function() Snacks.explorer() end, desc = "Explorer (Snacks)" },
  },
  opts = {
    explorer = {
      preview = {
        enabled = true,
        width = 0.4,
      },
    },
    picker = { exclude = excluded, hidden = true },
  },
}
