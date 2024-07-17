vim.opt.termguicolors = true
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.number = true

-- set to true if you have a nerd font installed
vim.g.have_nerd_font = true

-- enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- tab
vim.opt.tabstop = 2 -- set the number of spaces that a <tab> in the file counts for.
vim.opt.softtabstop = 2 -- insert/delete 4 spaces for a tab while editing.
vim.opt.shiftwidth = 2 -- set number of spaces for each step of (auto)indent.
vim.opt.expandtab = true -- converts tabs to spaces.
vim.opt.smarttab = true

vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.cmdheight = 0

-- obsidian, enable conceal. Accepts 0-3
vim.opt.conceallevel = 0

-- enable break indent
vim.opt.breakindent = true

-- sync clipboard between os and neovim.
vim.opt.clipboard = "unnamedplus"

-- disable line wrapping
vim.opt.wrap = false
vim.api.nvim_command("autocmd FileType markdown setlocal wrap")

-- save undo history
vim.opt.undofile = true
vim.opt.backup = false

-- case-insensitive searching unless \c or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- sets how neovim will display certain whitespace in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.title = true

-- set highlight on search
vim.opt.hlsearch = true

vim.opt.showcmd = true

vim.opt.laststatus = 0

vim.opt.scrolloff = 10

vim.opt.textwidth = 200

vim.opt.inccommand = "split"

vim.g.lazyvim_picker = "telescope"

vim.opt.backspace = { "start", "eol", "indent" }

vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })

vim.opt.splitbelow = true
vim.opt.splitright = true

-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })

-- add hyphen to what vim considers a word (for entire word selection)
vim.opt.iskeyword:append({ "-" })

-- stop auto commenting the next/previous lines when hitting CR or o for new line
vim.api.nvim_exec2([[ autocmd FileType * setlocal formatoptions-=ro ]], { output = true })
