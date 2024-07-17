return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options.component_separators = { left = "", right = "" }
    opts.options.section_separators = { left = "", right = "" }
    opts.sections.lualine_y = {
      {
        "filetype",
        icon = { color = { fg = "#262626" } },
        padding = { left = 1, right = 2 },
        color = { fg = "white" },
      },
      { "progress", padding = { left = 0, right = 1 } },
      { "location", padding = { left = 0, right = 1 } },
    }
  end,
}
