-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- disable snacks.nvim animate
vim.g.snacks_animate = false

vim.opt.scrolloff = 5

vim.opt.iskeyword:append("-")

vim.opt.clipboard:append({ "unnamed", "unnamedplus" })

vim.opt.incsearch = true

vim.opt.matchpairs:append("<:>")

vim.opt.hlsearch = true

vim.opt.ignorecase = true

vim.opt.smartcase = true
