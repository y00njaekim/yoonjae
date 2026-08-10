local mapKey = require("utils.keyMapper").mapKey

-- Neotree toggle
mapKey('<leader>e', ':Neotree toggle<CR>')

-- Neotree reveal
mapKey('<leader>E', ':Neotree reveal<CR>')

-- alpha dashboard
mapKey('<leader>a', ':Alpha<CR>')

-- pane navigation 
mapKey('<C-h>', '<C-w>h') -- Left
mapKey('<C-j>', '<C-w>j') -- Down
mapKey('<C-k>', '<C-w>k') -- Up
mapKey('<C-l>', '<C-w>l') -- Right

-- clear search highlights 
mapKey('<leader>h', ':nohlsearch<CR>')

-- copy relative file path with line number
mapKey('<leader>yl', function()
	local filepath = vim.fn.expand('%:.')
	if filepath == '' then
		vim.notify('Current buffer has no file path', vim.log.levels.WARN)
		return
	end

	local location = string.format('%s:%d', filepath, vim.fn.line('.'))
	vim.fn.setreg('+', location)
	vim.notify('Copied: ' .. location)
end)

mapKey('<leader>yl', function()
	local filepath = vim.fn.expand('%:.')
	if filepath == '' then
		vim.notify('Current buffer has no file path', vim.log.levels.WARN)
		return
	end

	local start_line = vim.fn.line('v')
	local end_line = vim.fn.line('.')
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local location = string.format('%s:%d-%d', filepath, start_line, end_line)
	vim.fn.setreg('+', location)
	vim.notify('Copied: ' .. location)
end, 'v')

-- indent 
mapKey('<', '<gv', 'v')
mapKey('>', '>gv', 'v')
