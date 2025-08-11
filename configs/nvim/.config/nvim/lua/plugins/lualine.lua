return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_c[4] = {
      "filename",
      path = 1,            -- 0=name, 1=relative, 2=absolute
      shorting_target = 0, -- keep every segment (no “…”)
    }

    return opts
  end,
}

