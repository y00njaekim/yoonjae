return {
	{
		"famiu/bufdelete.nvim",
		cmd = { "Bdelete", "Bwipeout" },
		keys = {
			{ "<leader>bd", "<cmd>Bdelete<CR>", desc = "Delete buffer, keep window layout" },
			{ "<leader>bD", "<cmd>Bdelete!<CR>", desc = "Delete buffer, discard changes" },
		},
	},
}
