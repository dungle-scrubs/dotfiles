return {
  "folke/snacks.nvim",
  dependencies = { "folke/persistence.nvim" },
  opts = function(_, opts)
    table.insert(opts.dashboard.preset.keys, 8, {
      icon = "S",
      key = "S",
      desc = "Select Session",
      action = function()
        local ok, p = pcall(require, "persistence")
        if ok then
          p.select()
        else
          vim.notify("persistence.nvim is not available", vim.log.levels.WARN)
        end
      end,
    })
  end,
}
