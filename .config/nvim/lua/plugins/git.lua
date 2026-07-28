return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
		keys = {
			{
				"]c",
				function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						require("gitsigns").nav_hunk("next")
					end
				end,
				desc = "Next Git change",
			},
			{
				"[c",
				function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						require("gitsigns").nav_hunk("prev")
					end
				end,
				desc = "Previous Git change",
			},
			{
				"<leader>gp",
				function()
					require("gitsigns").preview_hunk()
				end,
				desc = "Preview Git change",
			},
			{
				"<leader>gs",
				function()
					require("gitsigns").stage_hunk()
				end,
				desc = "Stage Git change",
			},
			{
				"<leader>gs",
				function()
					require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = "v",
				desc = "Stage selected Git change",
			},
			{
				"<leader>gu",
				function()
					require("gitsigns").undo_stage_hunk()
				end,
				desc = "Undo staged Git change",
			},
			{
				"<leader>gr",
				function()
					if vim.fn.confirm("Discard this Git change?", "&Discard\n&Cancel", 2) == 1 then
						require("gitsigns").reset_hunk()
					end
				end,
				desc = "Discard Git change",
			},
			{
				"<leader>gr",
				function()
					if vim.fn.confirm("Discard selected Git change?", "&Discard\n&Cancel", 2) == 1 then
						require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end
				end,
				mode = "v",
				desc = "Discard selected Git change",
			},
			{
				"<leader>gb",
				function()
					require("gitsigns").blame_line({ full = true })
				end,
				desc = "Show Git blame for line",
			},
			{
				"<leader>gd",
				function()
					require("gitsigns").diffthis("HEAD")
				end,
				desc = "Diff current file against HEAD",
			},
		},
	},
	{
		"dlyongemallo/diffview-plus.nvim",
		version = "*",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{
				"<leader>gv",
				"<cmd>DiffviewOpen HEAD<cr>",
				desc = "Review all local Git changes",
			},
			{
				"<leader>gc",
				function()
					vim.ui.input({
						prompt = "Compare against Git revision: ",
						default = "HEAD~1",
					}, function(revision)
						if revision and revision ~= "" then
							vim.api.nvim_cmd({
								cmd = "DiffviewOpen",
								args = { revision },
							}, {})
						end
					end)
				end,
				desc = "Compare against Git revision",
			},
			{
				"<leader>gh",
				"<cmd>DiffviewFileHistory %<cr>",
				desc = "Show current file Git history",
			},
			{
				"<leader>gH",
				"<cmd>DiffviewFileHistory<cr>",
				desc = "Show repository Git history",
			},
			{
				"<leader>gx",
				"<cmd>DiffviewClose<cr>",
				desc = "Close Git diff view",
			},
		},
	},
}
