-- Temporarily changes logsitter's prefix to the given color, logs,
-- then resets the prefix to its original state.
-- @param color The emoji symbol to set as the prefix for logsitter.
Log_with_color = function(color)
  local logsitter = require("logsitter")
  local default_prefix = logsitter.options.prefix
  logsitter.options.prefix = color
  logsitter.log()
  logsitter.options.prefix = default_prefix
end

return {
  "gaelph/logsitter.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local logsitter = require("logsitter")

    logsitter.setup({
      path_format = "fileonly",
      prefix = "🌶️ ",
      separator = ">",
      logging_functions = {
        lua = "vim.notify",
      },
    })

    vim.api.nvim_create_augroup("Logsitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = "Logsitter",
      pattern = "javascript,javascriptreact,typescript,typescriptreact,go,lua",
      callback = function()
        -- local keymaps = require("config/keymaps-custom")
        -- keymaps.logsitter(log_with_color)
      end,
    })
  end,
}
