return {
  "saghen/blink.cmp",
  optional = true,
  dependencies = { "Exafunction/windsurf.vim", "saghen/blink.compat" },
  opts = {
    sources = {
      compat = { "codeium" },
      providers = {
        codeium = {
          kind = "Codeium",
          score_offset = 100,
          async = true,
        },
      },
    },
  },
}
