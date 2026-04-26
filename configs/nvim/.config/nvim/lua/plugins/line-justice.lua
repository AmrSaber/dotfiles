return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim", "lewis6991/gitsigns.nvim" },
  lazy = false,
  config = function()
    local lj = require("line-justice")
    lj.setup({
      line_numbers = {
        -- theme = nil,
        overrides = {
          -- CursorLine    = { fg = "#FF966C", bold = true },
          -- AbsoluteAbove = { fg = "#565f89" },
          -- AbsoluteBelow = { fg = "#41664f" },
          -- RelativeAbove = { fg = "#7b9ac7" },
          -- RelativeBelow = { fg = "#6aa781" },
          -- WrappedLine   = { fg = "#565f89", italic = true },
        },
      },
    })

    local builtin = require("statuscol.builtin")
    require("statuscol").setup({
      relculright = true,
      segments = {
        { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
        { sign = { namespace = { "gitsigns" }, maxwidth = 1, colwidth = 1, auto = true }, click = "v:lua.ScSa" },
        { sign = { namespace = { "diagnostic/signs" }, maxwidth = 2, auto = true }, click = "v:lua.ScSa" },
        { sign = { name = { ".*" }, maxwidth = 2, colwidth = 1, auto = true, wrap = true }, click = "v:lua.ScSa" },
        { text = { lj.segment }, click = "v:lua.ScLa" },
      },
    })
  end,
}
