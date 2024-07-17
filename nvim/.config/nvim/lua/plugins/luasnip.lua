return {
  "L3MON4D3/LuaSnip",
  --[[ dependencies = {
    {
      "doxnit/cmp-luasnip-choice",
      config = function()
        require("cmp_luasnip_choice").setup({
          auto_open = true, -- Automatically open nvim-cmp on choice node (default: true)
        })
      end,
    },
  }, ]]
  opts = function(_, opts)
    require("config.keymaps-custom").luasnip()

    opts.history = true
    opts.delete_check_events = "TextChanged"
    opts.update_events = { "TextChanged", "TextChangedI" }
    opts.load_ft_func = require("luasnip.extras.filetype_functions").extend_load_ft({
      typescriptreact = { "typescript", "tsdoc" },
      markdown = { "lua", "json", "html" },
      html = { "css", "javascript" },
      liquid = { "html", "javascript", "css" },
      all = { "_" },
    })

    local function load()
      ---@diagnostic disable-next-line: assign-type-mismatch
      require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/lua/snippets" })
    end
    load()
  end,
}
