return {
  "folke/noice.nvim",
  event = "VeryLazy",
  keys = function()
    return {}
  end,
  opts = {
    timeout = 3000,

    commandes = {
      history = {
        filter_opts = { reverse = true },
      },
      pick = {
        filter_opts = { reverse = true },
      },
    },

    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },

    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
          },
        },
        view = "mini",
      },
      {
        filter = {
          event = "msg_show",
          find = "Starting Supermaven",
        },
        view = "mini",
      },

      {
        filter = {
          event = "msg_show",
          find = "Supermaven Free Tier is running",
        },
        view = "mini",
      },

      -- skp "lines" notifications
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+ lines --" },
            { find = "%d+ line --" },
            { find = "--No lines in buffer--" },
          },
        },
        opts = {
          set_skip = true,
        },
      },

      -- skip "No information available" messages
      {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = {
          skip = true,
        },
      },

      -- skin session manager errors
      {
        filter = {
          event = "notify",
          kind = "error",
          any = {
            { find = "No fold found" },
            { find = "'winwidth' cannot be smaller than 'winminwidth'" },
          },
        },
        opts = {
          skip = true,
        },
      },
      {
        filter = {
          event = "msg_show",
          kind = "lua_error",
          find = "foldminlines",
        },
        opts = {
          skip = true,
        },
      },
    },

    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
    },

    views = {
      cmdline_popup = {
        position = {
          row = 20,
        },
        border = {
          style = "none",
          padding = { 1, 3 },
        },
        filter_options = {},
        win_options = {
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        },
      },
      mini = {
        win_options = {
          winblend = 0,
          winhighlight = {},
        },
      },
    },
  },
}
