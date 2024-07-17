return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-file-browser.nvim",
    "danielvolchek/tailiscope.nvim",
    "olacin/telescope-cc.nvim",
    "gbprod/yanky.nvim",
    {
      "barrett-ruth/http-codes.nvim",
      config = true,
      -- or 'nvim-telescope/telescope.nvim'
      dependencies = "ibhagwan/fzf-lua",
    },
    {
      "benfowler/telescope-luasnip.nvim",
      module = "telescope._extensions.luasnip", -- if you wish to lazy-load
    },
    {
      "nvim-telescope/telescope.nvim",
      dependencies = {
        "nvim-telescope/telescope-node-modules.nvim",
      },
    },
  },
  keys = function()
    return {}
  end,
  opts = function()
    local actions = require("telescope.actions")
    local fb_actions = require("telescope").extensions.file_browser.actions

    local open_with_trouble = function(...)
      return require("trouble.sources.telescope").open(...)
    end
    local find_files_no_ignore = function()
      local action_state = require("telescope.actions.state")
      local line = action_state.get_current_line()
      LazyVim.pick("find_files", { no_ignore = true, default_text = line })()
    end
    local find_files_with_hidden = function()
      local action_state = require("telescope.actions.state")
      local line = action_state.get_current_line()
      LazyVim.pick("find_files", { hidden = true, default_text = line })()
    end

    require("telescope").load_extension("file_browser")
    require("telescope").load_extension("yank_history")
    require("telescope").load_extension("tailiscope")
    require("telescope").load_extension("conventional_commits")
    require("telescope").load_extension("luasnip")
    require("telescope").load_extension("node_modules")

    return {
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
        dynamic_preview_title = true,
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,

        -- open files in the first window that is an actual file.
        -- use the current window if no other window is available.
        get_selection_window = function()
          local wins = vim.api.nvim_list_wins()
          table.insert(wins, 1, vim.api.nvim_get_current_win())
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "" then
              return win
            end
          end
          return 0
        end,

        mappings = {
          i = {
            ["<c-t>"] = open_with_trouble,
            ["<a-t>"] = open_with_trouble,
            ["<a-i>"] = find_files_no_ignore,
            ["<a-h>"] = find_files_with_hidden,
            ["<C-Down>"] = actions.cycle_history_next,
            ["<C-Up>"] = actions.cycle_history_prev,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
          },
          n = {
            ["q"] = actions.close,
          },
        },

        pickers = {
          diagnostics = {
            theme = "ivy",
            initial_mode = "normal",
            layout_config = {
              preview_cutoff = 9999,
            },
          },
        },

        extensions = {
          file_browser = {
            theme = "dropdown",
            hijack_netrw = false,
            mappings = {
              -- your custom insert mode mappings
              ["n"] = {
                -- your custom normal mode mappings
                ["N"] = fb_actions.create,
                ["h"] = fb_actions.goto_parent_dir,
                ["<C-u>"] = function(prompt_bufnr)
                  for i = 1, 10 do
                    actions.move_selection_previous(prompt_bufnr)
                  end
                end,
                ["<C-d>"] = function(prompt_bufnr)
                  for i = 1, 10 do
                    actions.move_selection_next(prompt_bufnr)
                  end
                end,
              },
            },
          },
          tailiscope = {
            -- register to copy classes to on selection
            register = "a",
            -- indicates what picker opens when running Telescope tailiscope
            -- can be any file inside of docs dir but most useful opts are
            -- all, base, categories, classes
            -- These are also accesible by running Telescope tailiscope <picker>
            default = "base",
            -- icon indicates an item which can be opened in tailwind docs
            -- can be icon or false
            doc_icon = " ",
            -- if you would prefer to copy with/without class selector
            -- dot is maintained in display to differentiate class from other pickers
            no_dot = true,
            maps = {
              i = {
                back = "<C-h>",
                open_doc = "<C-o>",
              },
              n = {
                back = "b",
                open_doc = "od",
              },
            },
          },

          conventional_commits = {
            theme = "ivy", -- custom theme
            action = function(entry)
              -- entry = {
              --     display = "feat       A new feature",
              --     index = 7,
              --     ordinal = "feat",
              --     value = feat"
              -- }
              vim.print(entry)
            end,
            include_body_and_footer = true, -- Add prompts for commit body and footer
          },

          luasnip = require("telescope.themes").get_dropdown({
            theme = "ivy", -- custom theme
            border = false,
            preview = {
              check_mime_type = true,
            },
            search = function()
              -- ...
            end,
          }),
        },
      },
    }
  end,
}
