--[[
these need to be in a separate file from /config/keymaps.lua because, for
reasons I don't understand yet, I can't export objects with keymaps for
plugins AND use `vim.keymap.del` to unbind exiting LazyVim keymaps. So I'm
using /config/keymaps.lua only for unbinding.

single-line comments are just referencing what LazyVim already has mapped
so I don't need to.

example of telling which-key to ignore a keymap:
map("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

--]]

local M = {}
local wk = require("which-key")
local opts = { noremap = true, silent = true }

_G.map = vim.keymap.set

-- registers
map("n", "x", '"_x')

-- jumplist
map("n", "<C-i>", "<C-I>", { desc = "Jump forward", noremap = true, silent = true })

-- increment/decrement
-- map("n", "+", "<C-a>")
-- map("n", "-", "<C-x>")

-- select all
map("n", "<C-a>", "gg<S-v>G")

-- change casing
map("x", "U", ":<C-u>normal! gU<CR>")

-- map("n", "<Leader>q", ":quit<Return>", opts)
map("n", "<Leader>Q", ":qa<Return>", { desc = "Quit all", noremap = true, silent = true })
map("n", "QQ", ":q!<enter>", opts)
map("n", "WW", ":w!<enter>", opts)

-- scroll vertically half a screen while keeping the cursor in the center
map("n", "<c-d>", "<c-d>zz", { noremap = true })
map("n", "<c-u>", "<c-u>zz", { noremap = true })

-- join lines while keeping the cursor stationary
map("n", "J", "mzJ`z", opts)
map("n", "<leader>j", ":TSJToggle<cr>", opts)

-- find prev/next occurrence of a searched pattern, then center line on screen and open any collapsed folds
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- line(s) movement
map("v", "J", ":m '>+2<cr>gv=gv", opts)

map("v", "K", ":m '<-1<cr>gv=gv", opts)

-- by default, Neovim / Vim will overwrite your paste register if you paste over some text.
-- this keymap stops that behavior and you retain your original paste register to continue to apply the same changes over and over.
map("x", "p", [["_dP]], { noremap = true })

-- make Y behave like C and D (yank until end of line)
map("n", "Y", "y$", { noremap = true })

-- WHEN in insert mode and while a popup is visible, <esc> will take you to normal mode, instead of requiring you to press <c-e> first.
map("i", "<esc>", 'pumvisible() ? "\\<esc>\\<esc>" : "\\<esc>"', { expr = true, noremap = true })

-- location list
map("n", "<leader>;l", "<cmd>lopen<cr>", { desc = "Location List" })

-- toggle bool
map({ "n", "v" }, "<leader>zz", function()
  require("toggle-bool").toggle_bool()
end, { desc = "Toogle boolean" })

-- refactor
wk.register({
  ["<leader>"] = {
    r = {
      function()
        require("refactoring").select_refactor({
          show_success_message = true,
        })
      end,
      "Refactor",
    },
  },
}, { mode = { "v" } })

-- [[ api ]]
-- see languages/hurl-autocommands.lua

-- [[ dial ]]
M.dial = {
  keys = function(d)
    return {
      {
        "<leader>zk",
        function()
          return d.dial(true)
        end,
        expr = true,
        desc = "Increment",
        mode = { "n", "v" },
      },
      {
        "<leader>zj",
        function()
          return d.dial(false)
        end,
        expr = true,
        desc = "Decrement",
        mode = { "n", "v" },
      },
    }
  end,
}

-- [[ flash ]]
wk.register({
  ["/"] = {
    name = "+Flash",
    ["/"] = {
      function()
        require("flash").jump()
      end,
      "Flash",
    },
    ["?"] = {
      function()
        require("flash").treesitter()
      end,
      "Flash Treesitter",
    },
  },
})

map("c", "<c-s>", function()
  require("flash").toggle()
end, { desc = "Toggle Flash Search" })

-- [[ files ]]
wk.register({
  ["<leader>k"] = {
    name = "+Files",
    k = {
      ":lua require('oil.actions').parent.callback()<cr>",
      "Oil",
    },
    n = {
      "<cmd>enew<cr>",
      "New file",
    },
    e = {
      function()
        require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
      end,
      "NeoTree (Root Dir)",
    },
    E = {
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
      end,
      "NeoTree (cwd)",
    },
    c = {
      ":Neotree position=current<cr>",
      "NeoTree (Netrw style)",
    },
    w = {
      ":update<cr>",
      "Save file",
    },
  },
})

-- [[ formatting ]]
wk.register({
  ["<leader>f"] = {
    name = "+Formatting",
    f = {
      function()
        LazyVim.format({ force = true })
      end,
      "Format (forced)",
      mode = { "n", "v" },
    },
    i = {
      function()
        require("conform").format({ formatters = { "injected" }, timeout_ms = 3001 })
      end,
      "Format injected languages",
      mode = { "n", "v" },
    },
  },
})

wk.register({
  ["<leader>f"] = {
    name = "+Formatting",
  },
}, { mode = { "v" } })

-- [[ obsidian ]]
wk.register({
  ["<leader>o"] = {
    name = "+Obsidian",
    c = { ":ObsidianToggleCheckbox<cr>", "Toggle checkbox" },
    e = { ":ObsidianExtractNote<cr>", "Extract text to note", mode = { "n", "v" } },
    f = { ":ObsidianFollowLink<cr>", "Follow link" },
    l = { ":ObsidianLinkNew<cr>", "New link" },
    o = { ":ObsidianQuickSwitch<cr>", "Quick switch (Telescope)" },
    n = {
      name = "+New",
      n = { ":ObsidianNew<cr>", "New note" },
      t = { ":ObsidianToday<cr>", "Today" },
      T = { ":ObsidianTomorrow<cr>", "Tomorrow" },
      y = { ":ObsidianYesterday<cr>", "Yesterday" },
    },
    N = { ":ObsidianRename<cr>", "Rename" },
    b = { ":ObsidianBacklinks<cr>", "Backlinks (Telescope)" },
    s = { ":ObsidianSearch<cr>", "Search (Telescope)" },
    t = { ":ObsidianTags<cr>", "Tags (Telescope)" },
    T = { ":ObsidianTemplate<cr>", "Templates (Telescope)" },
  },
})

wk.register({
  ["<leader>O"] = {
    name = "+Obsidian",
  },
}, { mode = { "v" } })

-- [[ sessions / projects]]
wk.register({
  ["<leader>p"] = {
    name = "+Projects / Sessions",
    r = {
      function()
        require("persistence").load()
      end,
      "Restore session",
    },
    R = {
      function()
        require("persistence").load({ last = true })
      end,
      "Restore last session",
    },
    S = {
      function()
        require("persistence").stop()
      end,
      "Don't save session",
    },
    o = {
      ":Telescope neovim-project history<cr>",
      "Project history",
    },
    d = {
      ":Telescope neovim-project discover<cr>",
      "Folder",
    },
  },
})

-- [[ buffers ]]
wk.register({
  ["<leader>b"] = {
    name = "+Buffers / Bufferline",
    l = { ":bnext!<cr>", "Go to next buffer" },
    h = { ":bprevious!<cr>", "Go to previous buffer" },
    x = {
      function(n)
        LazyVim.ui.bufremove(n)
      end,
      "Delete buffer",
    },
    X = { "<cmd>:bd<cr>", "Delete buffer and window" },
    b = { "<leader>bb", "Switch to other buffer" },
    p = { "<Cmd>BufferLineTogglePin<CR>", "Toggle pin" },
    P = { "<Cmd>BufferLineGroupClose ungrouped<CR>", "Delete non-pinned buffers" },
    o = { "<Cmd>BufferLineCloseOthers<CR>", "Delete other buffers" },
    R = { "<Cmd>BufferLineCloseRight<CR>", "Delete buffers to the right" },
    L = { "<Cmd>BufferLineCloseLeft<CR>", "Delete buffers to the left" },
    n = {
      function()
        require("neo-tree.command").execute({ source = "buffers", toggle = true })
      end,
      "NeoTree Buffer Explorer",
    },
  },
})

-- [[ splits ]]
wk.register({
  ["<leader>w"] = {
    name = "+Splits / Save",
    n = {
      name = "+New",
      h = { ":FocusSplitLeft<cr>", "Split left" },
      j = { ":FocusSplitDown<cr>", "Split below" },
      k = { ":FocusSplitUp<cr>", "Split above" },
      l = { ":FocusSplitRight<cr>", "Split right" },
      n = { ":FocusSplitNicely<cr>", "Split nicely" },
    },
    x = { "<C-w>c", "Close split" },
    ["<cr>"] = { ":FocusMaxOrEqual<cr>", "Max or equal" },
    f = {
      name = "+Toggle focus",
      f = { ":FocusToggle<cr>", "Toggle focus (global)" },
      w = { ":FocusToggleWindow<cr>", "Toggle focus (window)" },
      b = { ":FocusToggleWindow<cr>", "Toggle focus (buffer)" },
    },
  },
})

-- [[ tabs / terminal ]]
local lazyterm = function()
  LazyVim.terminal(nil, { cwd = LazyVim.root() })
end
wk.register({
  ["<leader>t"] = {
    name = "+Tabs / Terminal",
    o = { "<cmd>tabonly<cr>", "Close other tabs" },
    n = { "<cmd>tabnew<cr>", "New tab" },
    l = { "<cmd>tabnext<cr>", "Next tab" },
    h = { "<cmd>tabprevious<cr>", "Previous tab" },
    x = { "<cmd>tabclose<cr>", "Close tab" },
    t = { lazyterm, "Terminal (Root Dir)" },
    T = {
      function()
        LazyVim.terminal()
      end,
      "Terminal (cwd)",
    },
  },
})

-- map("n", "<A-h>", "<cmd>tabprevious<cr>")
-- map("n", "<A-l>", "<cmd>tabnext<cr>")

-- [[ quickfix list ]]
wk.register({
  ["<leader>q"] = {
    name = "+Quickfix",
    q = { "<cmd>copen<cr>", "Open quickfix list" },
    h = { vim.cmd.cprev, "Previous quickfix" },
    l = { vim.cmd.cnext, "Next quickfix" },
  },
})

-- [[ database ]]
wk.register({
  ["<leader>d"] = {
    name = "+Database",
    d = { "<cmd>DBUI<cr>", "Open database" },
  },
})

-- [[ completion (cmp) ]]
-- https://github.com/L4MON4D3/LuaSnip/blob/master/DOC.md
M.cmp = function(cmp)
  local down_behavior = {
    i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
    c = function()
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete()
      end
    end,
  }

  local up_behavior = {
    i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
    c = function()
      if cmp.visible() then
        cmp.select_prev_item()
      else
        -- if previous item doesn't exist then this should trigger some other action
      end
    end,
  }

  return {
    ["<C-p>"] = function()
      if cmp.visible() then
        cmp.select_prev_item()
      else
        -- want to use Yanky's picker here, to paste in insert mode,
        -- but only if the completion popup isn't visible.
        if LazyVim.pick.picker.name == "telescope" then
          require("telescope").extensions.yank_history.yank_history({})
        else
          vim.cmd([[YankyRingHistory]])
        end
      end
    end,
    ["<C-b>"] = cmp.mapping.scroll_docs(-3),
    ["<C-f>"] = cmp.mapping.scroll_docs(5),
    ["<C-Space>"] = cmp.mapping.complete(),

    -- Although I want the completion to automatically appear,
    -- I only want <cr> to complete if I've intentionally select an item
    ["<CR>"] = cmp.mapping({
      i = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
        else
          fallback()
        end
      end,
      c = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
        else
          fallback()
        end
      end,
      s = cmp.mapping.confirm({ select = true }),
    }),
    ["<S-CR>"] = LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    ["<C-e>"] = cmp.mapping.abort(),
    ["<C-CR>"] = function(fallback)
      cmp.abort()
      fallback()
    end,
    ["<Down>"] = down_behavior,
    ["<C-j>"] = down_behavior,
    ["<Up>"] = up_behavior,
    ["<C-k>"] = up_behavior,
  }
end

-- [[ luasnip ]]
M.luasnip = function()
  local ls = require("luasnip")
  map({ "i", "s" }, "<C-l>", function()
    ls.jump(1)
  end)
  map({ "i", "s" }, "<C-h>", function()
    ls.jump(-1)
  end)
  map({ "i", "s" }, "<C-k>", function()
    if ls.choice_active() then
      ls.change_choice(-1)
    end
  end)
  map({ "i", "s" }, "<C-j>", function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end)
end

-- [[ comments / copilot / annotations ]]
local leader_c_n_v = {
  a = {
    require("config/functions").pick_copilot_action("prompt"),
    "Prompt actions (Telescope)",
  },
  C = {
    function()
      local input = vim.fn.input("Quick Chat: ")
      if input ~= "" then
        require("CopilotChat").ask(input)
      end
    end,
    "Quick Chat",
  },
  h = {
    function()
      return require("CopilotChat").toggle()
    end,
    "Copilot (toggle)",
  },
  o = {
    function()
      require("CopilotChat").open({
        window = {
          layout = "float",
          title = "Quickie",
        },
      })
    end,
    "Toggle Copilot Chat (popup)",
  },
  r = {
    function()
      return require("CopilotChat").reset()
    end,
    "Reset chat",
  },
  x = {
    require("config/functions").pick_copilot_action("help"),
    "Diagnostic help (Telescope)",
  },
}

local leader_c = {
  ["<leader>c"] = {
    name = "+Comments / Copilot / Annotations",
    A = {
      function()
        ---@diagnostic disable-next-line: missing-parameter
        require("neogen").generate()
      end,
      "Generate Annotations (Neogen)",
    },
  },
}

local leader_c_v = {
  ["<leader>c"] = {
    name = "+Comments / Copilot",
  },
}

leader_c["<leader>c"] = vim.tbl_deep_extend("force", leader_c["<leader>c"], leader_c_n_v)
leader_c_v["<leader>c"] = vim.tbl_deep_extend("force", leader_c_v["<leader>c"], leader_c_n_v)

wk.register(leader_c, { mode = { "n" } })
wk.register(leader_c_v, { mode = { "v" } })

-- [[ misc ]]
wk.register({
  ["<leader>m"] = {
    name = "+Misc",
    h = { ":checkhealth<cr>", "Check health" },
    f = { ":ConformInfo<cr>", "Conform" },
    M = { "<cmd>Mason<cr>", "Mason" },
    l = { "<cmd>Lazy<cr>", "Lazy" },
    L = { "<cmd>LspInfo<cr>", "LSP info" },
    p = { "<cmd>lua require('package-info').change_version()<cr>", "Package.info - change version" },
    s = { ":StartupTime<cr>", "Startup time" },
    c = {
      name = "CodeSnap (screenshots)",
      c = { "<cmd>CodeSnap<cr>", "Save code snapshot to clipboard" },
      s = { "<cmd>CodeSnapSave<cr>", "Save code snapshot to desktop" },
    },
  },
})

M.easycolor = {
  keys = {
    { "<leader>mC", ":EasyColor<cr>", desc = "Color picker", mode = { "n", "v" } },
  },
}

-- [[ diagnostics ]]
wk.register({
  ["<leader>x"] = {
    name = "+Diagnostics",
    d = { "<cmd>Trouble diagnostics toggle filter.buf=1 focus=true<cr>", "Document diagnostics (Trouble)" },
    D = { "<cmd>Telescope diagnostics bufnr=1<cr>", "Document diagnostics (Telescope)" },
    h = {
      function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      "Previous Trouble/Quickfix Item",
    },
    k = { vim.diagnostic.open_float, "Line diagnostic popup" },
    l = {
      function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      "Next Trouble/Quickfix Item",
    },
    L = { "<md>Trouble loclist toggle focus=true<cr>", "Location List" },
    Q = { "<cmd>Trouble qflist toggle focus=true<cr>", "Quickfix List" },
    s = { "<cmd>Trouble symbols toggle focus=true<cr>", "Symbols (Trouble)" },
    S = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "LSP references/definitions/..." },
    t = { "<cmd>Trouble todo toggle focus=true<cr>", "Todo" },
    T = { "<cmd>Trouble todo toggle filter={tag={TODO,FIX,FIXME}} focus=true<cr>", "Todo/Fix/Fixme" },
    w = { "<cmd>Trouble diagnostics toggle focus=true<cr>", "Workspace diagnostics (Trouble)" },
    W = { "<cmd>Telescope diagnostics<cr>", "Workspace diagnostics (Telescope)" },
  },
})

-- [[ harpoon ]]
M.harpoon = function()
  local harpoon = require("harpoon")

  wk.register({
    ["<leader>;"] = {
      name = "+Harpoon",
      a = {
        function()
          harpoon:list():add()
        end,
        "Add to list",
      },
      [";"] = {
        function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        "Open list",
      },
      s = {
        function()
          harpoon:list():prev()
        end,
        "Previous item",
      },
      g = {
        function()
          harpoon:list():next()
        end,
        "Next item",
      },
    },
  })
end

-- [[ logsitter ]]
wk.register({
  ["<leader>i"] = {
    name = "+Logging",
    i = {
      function()
        require("logsitter").log()
      end,
      "Log with default",
    },
    g = {
      function()
        Log_with_color("🟢")
      end,
      "Log with 🟢",
    },
    r = {
      function()
        Log_with_color("🔴")
      end,
      "Log with 🔴",
    },
    o = {
      function()
        Log_with_color("🟠")
      end,
      "Log with 🟠",
    },
    y = {
      function()
        Log_with_color("🟡")
      end,
      "Log with 🟡",
    },
    b = {
      function()
        Log_with_color("🔵")
      end,
      "Log with 🔵",
    },
    p = {
      function()
        Log_with_color("🟣")
      end,
      "Log with 🟣",
    },
  },
})

-- [[ LSP ]]
wk.register({
  ["<leader>l"] = {
    name = "+LSP",
    d = { vim.lsp.buf.definition, "Goto definition" },
    D = { "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", "Goto definition (preview)" },
    r = { vim.lsp.buf.references, "Goto references" },
    R = { "<cmd>lua require('goto-preview').goto_preview_references()<CR>", "Goto references (preview)" },
    i = { vim.lsp.buf.implementation, "Goto implementation" },
    I = { "<cmd>lua require('goto-preview').goto_preview_type_implementation()<CR>", "Goto implementation (preview)" },
    y = { vim.lsp.buf.type_definition, "Goto type definition" },
    Y = { "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", "Goto type definition (preview)" },
    o = { vim.lsp.buf.declaration, "Goto type declaration" },
    O = { "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>", "Goto type declaration (preview)" },
    a = { vim.lsp.buf.code_action, "Code action", mode = { "n", "v" } },
    c = { vim.lsp.codelens.run, "Run codelens", mode = { "n", "v" } },
    C = { vim.lsp.codelens.refresh, "Refresh & display codelens" },
    n = { vim.lsp.buf.rename, "Rename" },
    N = { LazyVim.lsp.rename_file, "Rename file" },
    f = { vim.lsp.buf.format, "Format file" },
  },
})

wk.register({
  ["<leader>l"] = {
    name = "+LSP",
  },
}, { mode = { "v" } })

-- [[ git ]]
-- https://github.com/olacin/telescope-cc.nvim
wk.register({
  ["<leader>g"] = {
    name = "+Neogit",
    c = { "<cmd>Telescope git_commits<CR>", "Commits (Telescope)" },
    C = { require("config/functions").create_conventional_commit, "Conventional commit" },
    b = { ":Telescope git_branches<CR>", "Branches (Telescope)" },
    s = { "<cmd>Telescope git_status<CR>", "Status (Telescope)" },
    S = {
      function()
        require("neo-tree.command").execute({ source = "git_status", toggle = true })
      end,
      "Status (NeoTree)",
    },
  },
})

M.neogit = {
  keys = {
    { "<leader>gg", ":Neogit<cr>", desc = "Open" },
  },
}

M.gitsigns = function()
  local gs = package.loaded.gitsigns

  wk.register({
    ["<leader>h"] = {
      name = "+Hunks",
      l = {
        function()
          gs.nav_hunk("next")
        end,
        "Next Hunk",
      },
      h = {
        function()
          gs.nav_hunk("prev")
        end,
        "Prev Hunk",
      },
      H = {
        function()
          gs.nav_hunk("last")
        end,
        "Last Hunk",
      },
      L = {
        function()
          gs.nav_hunk("first")
        end,
        "First Hunk",
      },
      S = { gs.stage_buffer, "Stage Buffer" },
      u = { gs.undo_stage_hunk, "Undo Stage Hunk" },
      R = { gs.reset_buffer, "Reset Buffer" },
      p = { gs.preview_hunk_inline, "Preview Hunk Inline" },
      b = {
        function()
          gs.blame_line({ full = true })
        end,
        "Blame Line",
      },
      d = { gs.diffthis, "Diff This" },
      D = {
        function()
          gs.diffthis("~")
        end,
        "Diff This ~",
      },
    },
  })

  wk.register({
    ["<leader>h"] = {
      name = "+Hunks",
      s = { ":Gitsigns stage_hunk<CR>", "Stage Hunk" },
      r = { ":Gitsigns reset_hunk<CR>", "Reset Hunk" },
    },
  }, { mode = { "n", "v" } })

  wk.register({
    ["<leader>h"] = {
      name = "+Hunks",
      h = { ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk" },
    },
  }, { map = { "o", "x" } })
end

-- [[ neo tree ]]
M.neotree = {
  mappings = {
    ["<bs>"] = "navigate_up",
    ["."] = "set_root",
    ["H"] = "toggle_hidden",
  },
}

-- [[ noice ]]
wk.register({
  ["<leader>n"] = {
    name = "+Noice",
    L = {
      function()
        require("noice").cmd("last")
      end,
      "Last message",
    },
    H = {
      function()
        require("noice").cmd("history")
      end,
      "History",
    },
    a = {
      function()
        require("noice").cmd("all")
      end,
      "All",
    },
    d = {
      function()
        require("noice").cmd("dismiss")
      end,
      "Dismiss all",
    },
    t = {
      function()
        require("noice").cmd("pick")
      end,
      "Telescope picker",
    },
  },
})

-- [[ oil ]]
M.oil = {
  ["<CR>"] = "actions.select",
  ["<bs>"] = "actions.parent",
  ["H"] = "actions.toggle_hidden",
  ["<esc>"] = "actions.close",
}

-- [[ search ]]
wk.register({
  ["<leader>s"] = {
    name = "+Search",
    a = { "<cmd>Telescope autocommands<cr>", "Autocommands" },
    b = {
      "<cmd>Telescope current_buffer_fuzzy_find<cr>",
      "Buffer (fuzzy)",
    },
    B = { "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", "Lists open buffers" },
    c = { "<cmd>Telescope command_history<cr>", "Command history" },
    C = {
      ":Cheatsheet<CR>",
      "Cheatsheets",
    },
    f = {
      LazyVim.pick("auto"),
      "Files (root dir)",
    },
    F = {
      LazyVim.pick("auto", { root = false }),
      "Files (cwd)",
    },
    g = {
      LazyVim.pick("live_grep"),
      "Grep (root dir)",
    },
    G = {
      LazyVim.pick("live_grep", { root = false }),
      "Grep (cwd)",
    },
    h = {
      name = "+Help / Highlight / HTTP",
      h = {
        "<cmd>Telescope help_tags<cr>",
        "Help pages",
      },
      H = {
        "<cmd>Telescope highlights<cr>",
        "Highlight groups",
      },
      t = { "<cmd>HTTPCodes<cr>", "HTTP codes" },
    },
    j = { "<cmd>Telescope jumplist<cr>", "Jumplist" },
    k = {
      "<cmd>Telescope keymaps<cr>",
      "Key maps",
    },
    l = { "<cmd>Telescope loclist<cr>", "Location list" },
    L = { "<cmd>Telescope luasnip<cr>", "Luasnip snippets" },
    m = { "<cmd>Telescope marks<cr>", "Marks" },
    n = {
      name = "+Neovim",
      f = {
        LazyVim.pick.config_files(),
        "Lists Neovim files",
      },
      o = { "<cmd>Telescope vim_options<cr>", "Vim options" },
    },
    N = { ":Telescope node_modules list<cr>", "node_modules" },
    o = {
      name = "+Projects",
      o = {
        ":Telescope neovim-project history<cr>",
        "Project history",
      },
      d = {
        ":Telescope neovim-project discover<cr>",
        "Folder",
      },
    },
    O = { "<cmd>ObsidianSearch<cr>", "Obsidian" },
    p = {
      ":Telescope yank_history<cr>",
      "Yank history",
    },
    q = { "<cmd>Telescope quickfix<cr>", "Quickfix list" },
    r = { "<cmd>Telescope registers<cr>", "Registers" },
    R = { ":Spectre<cr>", "Search & Replace (Spectre)" },
    -- R = {
    --   function()
    --     local builtin = require("telescope.builtin")
    --     builtin.resume()
    --   end,
    --   "Resume the previous telescope picker",
    -- },
    s = {
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = LazyVim.config.get_kind_filter(),
        })
      end,
      "Symbol",
    },
    S = {
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols({
          symbols = LazyVim.config.get_kind_filter(),
        })
      end,
      "Symbol (workspace)",
    },
    x = {
      "<cmd>Telescope diagnostics bufnr=1<cr>",
      "Diagnostics (document)",
    },
    X = {
      "<cmd>Telescope diagnostics<cr>",
      "Diagnostics (workspace)",
    },
    t = {
      name = "+Telescope / Treesitter / TailwindCSS",
      t = { "<cmd>Telescope commands<cr>", "Telescope commands" },
      T = {
        function()
          local builtin = require("telescope.builtin")
          builtin.treesitter()
        end,
        "Lists Function names, variables, from Treesitter",
      },
      w = { "<cmd>Telescope tailiscope all<cr>", "TailwindCSS" },
      W = { "<cmd>Telescope tailiscope<cr>", "TailwindCSS" },
    },
    u = { "<cmd>Telescope undo<cr>", "Undo history" },
    v = {
      ":DevdocsOpenFloat<CR>",
      "DevDocs",
    },
    w = { LazyVim.pick("grep_string", { word_match = "-w" }), "Word (root dir)" },
    W = { LazyVim.pick("grep_string", { root = false, word_match = "-w" }), "Word (cwd)" },
  },
})

wk.register({
  ["<leader>s"] = {
    name = "+Search",
    p = {
      function()
        if LazyVim.pick.picker.name == "telescope" then
          require("telescope").extensions.yank_history.yank_history({})
        else
          vim.cmd([[YankyRingHistory]])
        end
      end,
      "Yank history",
    },
    w = { LazyVim.pick("grep_string", { word_match = "-w" }), "Selection (root dir)", mode = "v" },
    W = { LazyVim.pick("grep_string", { root = false, word_match = "-w" }), "Selction (cwd)", mode = "v" },
  },
}, { mode = "v" })

return M
