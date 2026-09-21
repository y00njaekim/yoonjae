return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
      },
      sections = {
        lualine_c = {},
      },
      inactive_sections = {
        lualine_c = {},
      },
    },
  },
}
