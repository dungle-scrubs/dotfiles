local excluded = {
  -- MacOS
  ".DS_Store",
}

return {
  desc = "Snacks File Explorer",
  recommended = true,
  "folke/snacks.nvim",
  opts = {
    explorer = {},
    picker = { exclude = excluded, hidden = true },
  },
}
