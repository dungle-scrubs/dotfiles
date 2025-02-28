local D = {}

---@param increment boolean
---@param g? boolean
function D.dial(increment, g)
  local mode = vim.fn.mode(true)
  -- Use visual commands for VISUAL 'v', VISUAL LINE 'V' and VISUAL BLOCK '\22'
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

return {
  "monaqa/dial.nvim",
  recommended = true,
  desc = "Increment and decrement numbers, dates, and more",
  keys = function()
    local keymaps = require("config.keymaps-custom").dial.keys(D)
    return keymaps
  end,
}
