return {
  "b0o/incline.nvim",
  dependencies = {},
  event = "BufReadPre",
  priority = 1200,
  config = function()
    local helpers = require("incline.helpers")
    require("incline").setup({
      window = {
        padding = 0,
        margin = { horizontal = 0 },
      },
      hide = {
        cursorline = true,
      },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
        local modified = vim.bo[props.buf].modified

        -- buffer name
        -- right now, we're just using filename by itself
        local rel_path = vim.fn.fnamemodify(filename, ":~:.")
        local bufname_with_rel_path = rel_path ~= "" and rel_path or "[No Name]"
        local display_bufname = vim.tbl_extend("force", { bufname_with_rel_path, " " }, {
          guifg = "#a0a0a0",
          guibg = "#070707",
        })

        -- modified indicator
        local icon = modified and vim.tbl_extend("force", { "● " }, { guifg = "#d6991d" }) or {}

        local buffer = {
          ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
          " ",
          { filename, gui = modified and "bold,italic" or "bold" },

          " ",
          icon,
          guibg = "#363944",
        }
        return buffer
      end,
    })
  end,
}
