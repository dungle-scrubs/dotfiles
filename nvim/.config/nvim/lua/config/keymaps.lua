-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "U", "<C-r>")

-- Delete operations to black register
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "dw", '"_dw')
vim.keymap.set("n", "diw", '"_diw')
vim.keymap.set("n", "daw", '"_daw')

vim.keymap.set("n", "<esc>", ":nohlsearch<cr><esc>")
