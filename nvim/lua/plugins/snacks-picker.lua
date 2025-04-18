local excluded = {
  -- MacOS
  ".DS_Store",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {},
      picker = { exclude = excluded },
    },
    keys = {
      -- find
      {
        "<leader>fC",
        function()
          Snacks.picker.files({ dirs = { "~/.config", "~/dotfiles" }, hidden = true })
        end,
        desc = "Find ~/.config file",
      },
      {
        "<leader>fd",
        function()
          Snacks.picker.files({ dirs = { "~/dev" } })
        end,
        desc = "Dev (~/dev)",
      },
      -- git
      -- Grep
      {
        "<leader>sd",
        function()
          Snacks.picker.grep({ dirs = { "~/dev" } })
        end,
        desc = "Grep (~/dev)",
      },
      -- search
      {
        "<leader>sx",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sX",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },
      -- ui
    },
  },
}
