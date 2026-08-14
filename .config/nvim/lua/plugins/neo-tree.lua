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
      filesystem = {
        window = {
          mappings = {
            ["/"] = "noop", -- fuzzy_finder 해제 → vim 기본 검색
            ["?"] = "noop", -- 역방향 검색도 vim 기본으로
            ["f"] = "fuzzy_sorter", -- 기본 "#" 에 걸려있던 fzy 정렬 필터
          },
        },
      },
      window = {
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["Y"] = function(state)
            local path = vim.fn.fnamemodify(state.tree:get_node():get_id(), ":.")
            vim.fn.setreg("+", path, "c")
            vim.notify("Copied: " .. path)
          end,
          ["gy"] = function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg("+", path, "c")
            vim.notify("Copied: " .. path)
          end,
        },
      },
    },
  },
}
