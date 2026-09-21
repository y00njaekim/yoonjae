return {
  {
    "dimtion/guttermarks.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "FileType" },
    opts = {
      local_mark = { priority = 100 },
      global_mark = { priority = 100 },
      special_mark = { priority = 100 },
      excluded_filetypes = { "NvimTree", "neo-tree", "alpha" },
    },
  },
}
