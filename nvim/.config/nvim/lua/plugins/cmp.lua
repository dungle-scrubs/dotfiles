local ELLIPSIS_CHAR = "…"
local MAX_LABEL_WIDTH = 50
local MIN_LABEL_WIDTH = 50

return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",
    "dmitmel/cmp-cmdline-history",
    "hrsh7th/cmp-path",
    "onsails/lspkind.nvim",
    "hrsh7th/cmp-emoji",
    "chrisgrieser/cmp_yanky",
    {
      "zbirenbaum/copilot-cmp",
      dependencies = "copilot.lua",
      opts = {},
      config = function(_, opts)
        local copilot_cmp = require("copilot_cmp")
        copilot_cmp.setup(opts)
        -- attach cmp source whenever copilot attaches
        -- fixes lazy-loading issues with the copilot cmp source
        LazyVim.lsp.on_attach(function(client)
          copilot_cmp._on_insert_enter({})
        end, "copilot")
      end,
    },
  },
  keys = {
    { "<tab>", false, mode = { "i", "s" } },
    { "<s-tab>", false, mode = { "i", "s" } },
  },
  opts = function(_, opts)
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    local keymaps = require("config.keymaps-custom")

    local auto_select = false

    opts.completion = {
      completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
    }
    --[[ enabled = function()
        return not require("luasnip").in_snippet()
      end, ]]

    opts.preselect = cmp.PreselectMode.None

    opts.formatting = {
      format = function(entry, vim_item)
        local label = vim_item.abbr
        local truncated_label = vim.fn.strcharpart(label, 0, MAX_LABEL_WIDTH)
        if truncated_label ~= label then
          vim_item.abbr = truncated_label .. ELLIPSIS_CHAR
        elseif string.len(label) < MIN_LABEL_WIDTH then
          local padding = string.rep(" ", MIN_LABEL_WIDTH - string.len(label))
          vim_item.abbr = label .. padding
        end
        return vim_item
      end,
    }

    opts.mapping = cmp.mapping.preset.insert(keymaps.cmp(cmp))

    opts.sources = cmp.config.sources({
      {
        group_index = 1,
        name = "copilot",
        priority = 100,
      },
      {
        group_index = 1,
        name = "nvim_lsp",
      },
      {
        group_index = 1,
        name = "path",
      },
      {
        group_index = 2,
        name = "buffer",
      },
      {
        group_index = 0,
        name = "lazydev",
      },
      {
        name = "luasnip",
        option = { use_show_condition = true },
        entry_filter = function()
          local context = require("cmp.config.context")
          local is_not_in_string = not context.in_treesitter_capture("string") and not context.in_syntax_group("String")
          local is_not_in_luasnip = function()
            local luasnip = require("luasnip")
            return luasnip.session.current_nodes[vim.api.nvim_get_current_buf()] == nil
          end
          return is_not_in_string and is_not_in_luasnip
        end,
      },
      { name = "emoji" },
      { name = "cmp_yanky" },
    })

    opts.window = {
      documentation = cmp.config.window.bordered(),
    }

    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
        { name = "cmdline_history" },
        { name = "path" },
      }),
    })
  end,
}
