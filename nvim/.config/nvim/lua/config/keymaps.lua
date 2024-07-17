--[[
NOTE:

This file is being used only for unbinding LazyVim keymaps using 
`vim.keymap.del` because I can't export keymap objects/functions AND
unbind at the same time for some LazyVim reason.

--]]

-- misc
vim.keymap.del("n", "<leader>L")

-- casing
vim.keymap.del("v", "U")

-- quit
vim.keymap.del("n", "<leader>qq")
-- vim.keymap.del("n", "Z")

-- Move Lines
vim.keymap.del("n", "<A-j>")
vim.keymap.del("n", "<A-k>")
vim.keymap.del("i", "<A-j>")
vim.keymap.del("i", "<A-k>")
vim.keymap.del("v", "<A-j>")
vim.keymap.del("v", "<A-k>")

-- buffers
-- vim.keymap.del("n", "<S-h>")
-- vim.keymap.del("n", "<S-l>")
vim.keymap.del("n", "[b")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "<leader>`")
vim.keymap.del("n", "<leader>bd")
vim.keymap.del("n", "<leader>bD")
vim.keymap.del("n", "<leader>bb")

-- new file
vim.keymap.del("n", "<leader>fn")

-- save file
vim.keymap.del({ "i", "x", "n", "s" }, "<C-s>")

-- lazy
vim.keymap.del("n", "<leader>l")

-- location list
vim.keymap.del("n", "<leader>xl")

-- quickfix list
vim.keymap.del("n", "<leader>xq")
vim.keymap.del("n", "[q")
vim.keymap.del("n", "]q")

-- formatting
vim.keymap.del({ "n", "v" }, "<leader>cf")

-- diagnostic
vim.keymap.del("n", "<leader>cd")
vim.keymap.del("n", "]d")
vim.keymap.del("n", "[d")
vim.keymap.del("n", "]e")
vim.keymap.del("n", "[e")
vim.keymap.del("n", "]w")
vim.keymap.del("n", "[w")

-- lazygit
-- vim.keymap.del("n", "<leader>gg")
vim.keymap.del("n", "<leader>gG")
vim.keymap.del("n", "<leader>gb")
vim.keymap.del("n", "<leader>gB")
vim.keymap.del("n", "<leader>gf")
vim.keymap.del("n", "<leader>gl")
vim.keymap.del("n", "<leader>gL")

-- floating terminal
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<c-/>")

-- windows
vim.keymap.del("n", "<leader>ww")
vim.keymap.del("n", "<leader>wd")
vim.keymap.del("n", "<leader>w-")
vim.keymap.del("n", "<leader>w|")
vim.keymap.del("n", "<leader>-")
vim.keymap.del("n", "<leader>|")
vim.keymap.del("n", "<leader>wm")

-- tabs
vim.keymap.del("n", "<leader><tab>l")
vim.keymap.del("n", "<leader><tab>o")
vim.keymap.del("n", "<leader><tab>f")
vim.keymap.del("n", "<leader><tab><tab>")
vim.keymap.del("n", "<leader><tab>]")
vim.keymap.del("n", "<leader><tab>d")
vim.keymap.del("n", "<leader><tab>[")
