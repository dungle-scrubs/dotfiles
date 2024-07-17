local group = vim.api.nvim_create_augroup("hurl", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = "*.hurl",
  callback = function()
    local wk = require("which-key")
    local bufnr = vim.api.nvim_get_current_buf()
    wk.register({
      ["<leader>a"] = {
        name = "+API",
        a = {
          "<cmd>HurlRunnerAt<CR>",
          "Run API request",
        },
        A = {
          "<cmd>HurlRunner<CR>",
          "Run all requests",
        },
        t = {
          "<cmd>HurlRunnerToEntry<CR>",
          "Run API request to entry",
        },
        m = {
          "<cmd>HurlToggleMode<CR>",
          "Toggle Hurl mode",
        },
        v = {
          "<cmd>HurlVerbose<CR>",
          "Run API in verbose mode",
        },
      },
    }, { buffer = bufnr })

    wk.register({
      ["<leader>a"] = {
        name = "+API",
        a = {
          "<cmd>HurlRunner<CR>",
          "Run API request",
          mode = "v",
        },
      },
    }, { mode = "v", buffer = bufnr })
  end,
})
