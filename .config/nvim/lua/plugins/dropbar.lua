return {
  {
    "Bekaboo/dropbar.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick file, class, or function in breadcrumbs",
      },
    },
  },
}
