return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
    opts = {
      window = {
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["Y"] = function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg("+", path, "c")
            vim.notify("Copied: " .. path)
          end,
          ["gy"] = function(state)
            local path = vim.fn.fnamemodify(state.tree:get_node():get_id(), ":.")
            vim.fn.setreg("+", path, "c")
            vim.notify("Copied: " .. path)
          end,
        },
      },
    },
  },
}
