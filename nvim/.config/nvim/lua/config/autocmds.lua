local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  desc = "Disable certain settings for minified files",
  group = vim.api.nvim_create_augroup("minified-files", { clear = true }),
  pattern = "*.min.js, *.min.css",
  callback = function()
    vim.cmd("setlocal noswapfile")
    vim.cmd("setlocal nocursorline")
    vim.cmd("setlocal nocursorcolumn")
    vim.cmd("syntax off")
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "dbout",
    "oil",
    "dev_doc",
    "gitsigns.blame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

local group = vim.api.nvim_create_augroup("lsp-typescript", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = "*.ts,*.tsx,*.js,*.jsx",
  callback = function()
    local wk = require("which-key")
    local bufnr = vim.api.nvim_get_current_buf()
    wk.register({
      ["<leader>l"] = {
        t = {
          name = "+TypeScript",
          d = {
            function()
              local params = vim.lsp.util.make_position_params()
              LazyVim.lsp.execute({
                command = "typescript.goToSourceDefinition",
                arguments = { params.textDocument.uri, params.position },
                open = true,
              })
            end,
            "Go to source definition",
          },
          f = {
            LazyVim.lsp.action["source.fixAll.ts"],
            "Fix all",
          },
          i = {
            LazyVim.lsp.action["source.addMissingImports.ts"],
            "Add missing imports",
          },
          I = {
            LazyVim.lsp.action["source.removeUnused.ts"],
            "Remove unused imports",
          },
          o = {
            LazyVim.lsp.action["source.organizeImports"],
            "Organize imports",
          },
          s = {
            LazyVim.lsp.action["source.sortImports"],
            "Sort imports",
          },
          r = {
            function()
              LazyVim.lsp.execute({
                command = "typescript.findAllFileReferences",
                arguments = { vim.uri_from_bufnr(0) },
                open = true,
              })
            end,
            "Find all file references",
          },
          v = {
            function()
              LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
            end,
            "Select TS workspace version",
          },
        },
      },
    }, { buffer = bufnr })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = group,
  desc = "Organize & sort imports on save",
  pattern = "*.ts,*.tsx,*.js,*.jsx",
  callback = function()
    local vtsls = require("vtsls")
    vtsls.commands.organize_imports()
    -- vtsls.commands.sort_imports()
  end,
})
