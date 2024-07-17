return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "yioneko/nvim-vtsls",
  },
  opts = function(_, opts)
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- Disable all included LazyVim LSP keymaps
    keys[#keys + 1] = { "<leader>cl", false }
    keys[#keys + 1] = { "gd", false }
    keys[#keys + 1] = { "gr", false }
    keys[#keys + 1] = { "gI", false }
    keys[#keys + 1] = { "gy", false }
    keys[#keys + 1] = { "gD", false }
    keys[#keys + 1] = { "<leader>ca", false, mode = { "n", "v" } }
    keys[#keys + 1] = { "<leader>cc", false, mode = { "n", "v" } }
    keys[#keys + 1] = { "<leader>cC", false }
    keys[#keys + 1] = { "<leader>cR", false }
    keys[#keys + 1] = { "<leader>cr", false }
    keys[#keys + 1] = { "<leader>cA", false }
    keys[#keys + 1] = { "<a-n>", false }
    keys[#keys + 1] = { "<a-p>", false }
    keys[#keys + 1] = { "<c-k>", false, mode = { "i" } }

    opts.inlay_hints.enabled = false

    ---@type fun(server:string, opts:_.lspconfig.options)
    local shopify_ls = function(_, opts)
      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")
      local util = require("lspconfig.util")

      local root_files = {
        ".theme-check.yml",
        ".git",
        ".shopifyignore",
      }

      if not configs.shopify_ls then
        configs.shopify_ls = {
          default_config = {
            name = "shopify_ls",
            cmd = { "shopify", "theme", "language-server" },
            filetypes = { "liquid" },
            --[[ root_dir = require("lspconfig/util").root_pattern(".theme-check.yml", ".git", ".shopifyignore") or require("lspconfig").util.find_git_ancestor
            or vim.fn.getcwd(), ]]
            single_file_support = true,
            root_dir = util.root_pattern(unpack(root_files)),
          },
        }
      end
      lspconfig.shopify_ls.setup(opts)
    end

    opts.setup.shopify_ls = shopify_ls
    opts.servers.shopify_ls = {}
  end,
}
