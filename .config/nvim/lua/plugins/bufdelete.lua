return {
	{
		"famiu/bufdelete.nvim",
		cmd = { "Bdelete", "Bwipeout" },
		keys = {
			{
				"<leader>bo",
				function()
					local current = vim.api.nvim_get_current_buf()
					local kept = 0
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
							if vim.bo[buf].modified then
								kept = kept + 1
							elseif not pcall(vim.api.nvim_buf_delete, buf, { force = false }) then
								kept = kept + 1
							end
						end
					end
					if kept > 0 then
						vim.notify("Kept " .. kept .. " modified or busy buffer(s)", vim.log.levels.INFO)
					end
				end,
				desc = "Delete other buffers",
			},
			{ "<leader>bd", "<cmd>Bdelete<CR>", desc = "Delete buffer, keep window layout" },
			{ "<leader>bD", "<cmd>%bdelete!<CR>", desc = "Delete all buffers, discard changes" },
		},
	},
}
