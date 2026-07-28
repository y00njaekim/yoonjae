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
          local started = pcall(vim.treesitter.start, args.buf)

          if started then
            for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
              vim.wo[win].foldmethod = "expr"
              vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
            end
          end
        end,
      })
    end,
  },
}
