return {
  {
    "dimtion/guttermarks.nvim",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "FileType" },
    opts = {
      excluded_filetypes = { "NvimTree", "neo-tree", "alpha" },
    },
  },
}
