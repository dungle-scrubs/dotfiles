local wk = require("which-key")
local M = {}

vim.api.nvim_create_user_command("Todos", function()
  require("fzf-lua").grep({ search = [[TODO:|todo!\(.*\)]], no_esc = true })
end, { desc = "Grep TODOs", nargs = 0 })

vim.api.nvim_create_user_command("Scratch", function()
  vim.cmd("bel 10new")
  local buf = vim.api.nvim_get_current_buf()
  for name, value in pairs({
    filetype = "scratch",
    buftype = "nofile",
    bufhidden = "hide",
    swapfile = false,
    modifiable = true,
  }) do
    vim.api.nvim_set_option_value(name, value, { buf = buf })
  end
end, { desc = "Open a scratch buffer", nargs = 0 })

---@type table<string, LazyFloat>
local terminals = {}

--- Opens an interactive floating terminal.
---@param cmd? string
---@param opts table
---@return LazyFloat
function M.float_term(cmd, opts)
  opts = vim.tbl_deep_extend("force", {
    ft = "lazyterm",
    size = { width = 0.7, height = 0.7 },
    persistent = true,
  }, opts)

  local termkey = vim.inspect({ cmd = cmd or "shell", cwd = opts.cwd, count = vim.v.count1 })

  if terminals[termkey] and terminals[termkey]:buf_valid() then
    terminals[termkey]:toggle()
  else
    terminals[termkey] = require("lazy.util").float_term(cmd, opts)
    local buf = terminals[termkey].buf
    vim.b[buf].lazyterm_cmd = cmd

    vim.api.nvim_create_autocmd("BufEnter", {
      buffer = buf,
      callback = function()
        vim.cmd.startinsert()
      end,
    })
  end

  return terminals[termkey]
end

M.create_conventional_commit = function()
  local actions = require("telescope._extensions.conventional_commits.actions")
  local picker = require("telescope._extensions.conventional_commits.picker")
  local themes = require("telescope.themes")

  -- if you use the picker directly you have to provide your theme manually
  local opts = {
    action = actions.prompt,
    include_body_and_footer = true,
  }
  opts = vim.tbl_extend("force", opts, themes["get_ivy"]())
  picker(opts)
end

_G.register_wkeys = function(mappings)
  if type(mappings[1]) ~= "table" then
    local opts = mappings.opts or { prefix = "<leader>" }
    mappings.opts = nil -- Remove opts from mappings
    wk.register(mappings, opts)
  else
    for _, tbl in ipairs(mappings) do
      local opts = tbl.opts or { prefix = "<leader>" }
      tbl.opts = nil -- Remove opts from tbl
      wk.register(tbl, opts)
    end
  end
end

--- Returns Copilot chat actions for the given kind.
---@param kind string
---@return function
M.pick_copilot_action = function(kind)
  return function()
    local actions = require("CopilotChat.actions")
    local items = actions[kind .. "_actions"]()
    if not items then
      LazyVim.warn("No " .. kind .. " found on the current line")
      return
    end
    local ok = pcall(require, "fzf-lua")
    require("CopilotChat.integrations." .. (ok and "fzflua" or "telescope")).pick(items)
  end
end

_G.table_contains_string = function(data, search_string)
  if type(data) == "table" then
    for key, var in pairs(data) do
      if table_contains_string(var, search_string) then
        return true
      end
    end
  elseif type(data) == "string" then
    if string.match(data, search_string) then
      return true
    end
  end
  return false
end

return M
