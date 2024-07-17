return {
  "stevearc/conform.nvim",
  keys = function()
    return {}
  end,
  opts = {
    formatters_by_ft = {
      fish = nil,
      liquid = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
    },
    formatters = {
      prettier = {
        condition = function(ctx)
          return vim.fs.find({
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.yml",
            ".prettierrc.yaml",
            ".prettierrc.json5",
            ".prettierrc.js",
            "prettier.config.js",
            ".prettierrc.mjs",
            "prettier.config.mjs",
            ".prettierrc.cjs",
            "prettier.config.cjs",
            ".prettierrc.toml",
          }, { path = ctx.filename, upward = true })[1]
        end,

        --[[ prepend_args = function(ctx)
          local filetype = require("plenary.filetype").detect_from_extension(ctx.filename)

          if filetype ~= "astro" then
            return {}
          end

          return {
            "--stdin-filepath",
            ctx.bufname,
            "--plugin=prettier-plugin-astro",
          }
        end, ]]
      },
    },
  },
}
