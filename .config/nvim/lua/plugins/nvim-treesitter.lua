return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    commit = "4916d6592ede8c07973490d9322f187e07dfefac",
    lazy = false,
    build = ":TSUpdate",

    config = function()
      local treesitter = require("nvim-treesitter")

      treesitter.install({ "python" })

      local group = vim.api.nvim_create_augroup("user-treesitter", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "lua", "python" },
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
