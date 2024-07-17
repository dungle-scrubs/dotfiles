local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local function get_dynamic_path()
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  local module_name = "cn"

  -- Function to check if a file exports the module
  local function file_exports_module(file_path)
    local content = vim.fn.readfile(file_path)
    for _, line in ipairs(content) do
      if line:match("export%s+.*%f[%w]" .. module_name .. "%f[%W]") then
        return true
      end
    end
    return false
  end

  -- Check files in the current directory
  local files = vim.fn.glob(current_dir .. "/*.{js,ts}", 0, 1)
  for _, file in ipairs(files) do
    if file_exports_module(file) then
      local relative_path = vim.fn.fnamemodify(file, ":t:r")
      return "./" .. relative_path
    end
  end

  -- If not found in current directory, use LSP to search
  local result = vim.lsp.buf_request_sync(0, "textDocument/definition", {
    textDocument = { uri = vim.uri_from_fname(current_file) },
    position = { line = 0, character = 0 },
    context = { includeDeclaration = true },
  }, 1000)

  if result and result[1] and result[1].result and #result[1].result > 0 then
    for _, def in ipairs(result[1].result) do
      local uri = def.uri
      local path = vim.uri_to_fname(uri)
      if file_exports_module(path) then
        local relative_path = vim.fn.fnamemodify(path, ":~:.")
        relative_path = relative_path:gsub("%.js$", ""):gsub("%.ts$", "")
        return relative_path
      end
    end
  end

  -- If still not found, return a default path
  return "utils/cn"
end

local snippets = {
  s("xx", {
    t("import * as React from 'react'"),
    f(function(args)
      return string.match(args[1][1], "cn") and { "", "import { cn } from " .. get_dynamic_path() .. ";" } or ""
    end, { 2 }),
    t({ "", "" }),
    t({ "", "" }),
    t("type "),
    l(l._1:sub(1, 1):upper() .. l._1:sub(2, -1), { 1 }),
    t("Props = React.HTMLAttributes<HTMLDivElement> & {"),
    t({ "", "\tclassName?: string;" }),
    f(function(args)
      return args[1][1] == "{ children }" and { "", "\tchildren: React.ReactNode;" } or ""
    end, { 3 }),
    t({ "", "}" }),
    t({ "", "" }),
    t({ "", "" }),
    t("export function "),
    i(1, "someFunction"),
    t("(props: "),
    l(l._1:sub(1, 1):upper() .. l._1:sub(2, -1), { 1 }),
    t("Props"),
    t(") {"),
    t({ "", "\tconst { className" }),
    f(function(args)
      return args[1][1] ~= "" and ", children" or ""
    end, { 3 }),
    t({ ",...restProps } = props;", "", "" }),
    t("\treturn ("),
    t({ "", "\t\t" }),
    t("<div className={"),
    c(2, {
      t("cn('', className)"),
      t("className"),
    }),
    t("} {...restProps}>"),
    c(3, {
      t(""),
      t("{ children }"),
    }),
    t("</div>"),
    t({ "", "\t" }),
    t(")"),
    t({ "", "}" }),
  }),
}

-- for some reason, luasnip won't extend the snippets from typescript.lua
local typescript_snippets = require("snippets.typescript")

local combined_snippets = vim.list_extend(snippets, typescript_snippets)

return combined_snippets
