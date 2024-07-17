return {
  "rmagatti/goto-preview",
  config = function()
    require("goto-preview").setup({
      width = 120, -- Width of the floating window
      height = 15, -- Height of the floating window
      border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- Border characters of the floating window
      default_mappings = true,
      debug = false, -- Print debug information
      opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
      resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
      references = { -- Configure the telescope UI for slowing the references cycling window.
        telescope = require("telescope.themes").get_dropdown({ hide_preview = false }),
      },
      -- These two configs can also be passed down to the goto-preview definition and implementation calls for one off "peak" functionality.
      focus_on_open = true, -- Focus the floating window when opening it.
      dismiss_on_move = false, -- Dismiss the floating window when moving the cursor.
      force_close = true, -- passed into vim.api.nvim_win_close's second argument. See :h nvim_win_close
      bufhidden = "wipe", -- the bufhidden option to set on the floating window. See :h bufhidden
      stack_floating_preview_windows = true, -- Whether to nest floating windows
      preview_window_title = { enable = true, position = "left" }, -- Whether

      post_open_hook = function(buf, win)
        -- Disable ability to modify buffer in preview
        local orig_state = vim.api.nvim_buf_get_option(buf, "modifiable")
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        vim.api.nvim_create_autocmd({ "WinLeave" }, {
          buffer = buf,
          callback = function()
            vim.api.nvim_win_close(win, false)
            vim.api.nvim_buf_set_option(buf, "modifiable", orig_state)
            return true
          end,
        })

        -- close the current preview window with <Esc>
        vim.keymap.set("n", "<Esc>", function()
          vim.api.nvim_win_close(win, true)
        end, { buffer = true })

        -- also close with q
        vim.keymap.set("n", "q", function()
          vim.api.nvim_win_close(win, true)
        end, { buffer = true })
      end,
    })
  end,
}
