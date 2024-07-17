vim.api.nvim_buf_set_keymap(
  0,
  "n",
  "<leader>il",
  'viwyo{{ <C-R>" }}<Esc>',
  { desc = "Liquid (not in tag)", noremap = true }
)
vim.api.nvim_buf_set_keymap(0, "n", "<leader>iL", 'viwyoecho <C-R>"<Esc>', { desc = "Liquid (in tag)", noremap = true })
