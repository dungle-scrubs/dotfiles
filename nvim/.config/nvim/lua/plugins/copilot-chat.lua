return {
  "CopilotC-Nvim/CopilotChat.nvim",
  keys = function()
    return {}
  end,
  opts = function()
    local user = vim.env.USER or "User"
    user = user:sub(1, 1):upper() .. user:sub(2)
    return {
      model = "gpt-4",
      auto_insert_mode = true,
      show_help = true,
      question_header = "  " .. user .. " ",
      answer_header = "  Copilot ",
      window = {
        width = 0.4,
      },
      selection = function(source)
        local select = require("CopilotChat.select")
        return select.visual(source) or select.buffer(source)
      end,

      -- default mappings
      mappings = {
        complete = {
          detail = "Use @<Tab> or /<Tab> for options.",
          insert = "<CR>",
        },
        close = {
          normal = "q",
          insert = "<C-c>",
        },
        reset = {
          normal = "<C-l>",
          insert = "<C-l>",
        },
        submit_prompt = {
          normal = "<C-s>",
          insert = "<C-s>",
        },
        accept_diff = {
          normal = "<C-y>",
          insert = "<C-y>",
        },
        yank_diff = {
          normal = "gy",
        },
        show_diff = {
          normal = "gd",
        },
        show_system_prompt = {
          normal = "gp",
        },
        show_user_selection = {
          normal = "gs",
        },
      },
    }
  end,
  config = function(_, opts)
    local chat = require("CopilotChat")
    require("CopilotChat.integrations.cmp").setup()

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-chat",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
      end,
    })

    chat.setup(opts)
  end,
}
