return {
  {
    "coffebar/neovim-project",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim", tag = "0.1.4" },
      { "Shatur/neovim-session-manager" },
    },
    enabled = false,
    lazy = false,
    priority = 100,
    init = function() end,
    opts = {
      projects = { -- define project roots
        "~/dev/*",
        "~/dev/client/*",
        "~/dev/apps/*",
        "~/.config/*",
        "~/vaults/*",
      },
      last_session_on_startup = false,
      dashboard_mode = false,
      session_manager_opts = {
        autosave_ignore_dirs = { "*" },
        autosave_ignore_filetypes = { "*" },
      },
    },
  },
}
