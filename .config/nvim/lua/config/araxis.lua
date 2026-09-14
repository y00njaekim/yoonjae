local M = {}

local executable = "/Applications/Araxis Merge.app/Contents/Utilities/compare"

local function warn(message)
	vim.notify(message, vim.log.levels.WARN, { title = "Diffview → Araxis" })
end

local function snapshot(file, path)
	local lines = file.nulled and {} or vim.api.nvim_buf_get_lines(file.bufnr, 0, -1, false)
	if not file.nulled then
		local format = vim.bo[file.bufnr].fileformat
		if format == "dos" then
			for i, line in ipairs(lines) do
				if i < #lines or vim.bo[file.bufnr].endofline then
					lines[i] = line .. "\r"
				end
			end
		end
		if vim.bo[file.bufnr].endofline then
			lines[#lines + 1] = ""
		end
	end
	if vim.fn.writefile(lines, path, "b") ~= 0 then
		error("Cannot write comparison snapshot: " .. path)
	end
	vim.fn.setfperm(path, "r--------")
end

function M.open()
	local ok, lib = pcall(require, "diffview.lib")
	local view = ok and lib.get_current_view() or nil
	local layout = view and view.cur_layout
	if not (view and view.cur_entry and layout and layout.a and layout.b) then
		warn("Open a file in Diffview before using this shortcut.")
		return
	end
	if layout.c or layout.d then
		warn("This shortcut supports two-way comparisons; switch to a two-way layout first.")
		return
	end
	local left, right = layout.a.file, layout.b.file
	if not left or not right then
		warn("Diffview is still loading the comparison.")
		return
	end
	for _, file in ipairs({ left, right }) do
		if file.binary then
			warn("Binary files cannot be exported from Diffview's text buffers.")
			return
		end
		if not file.nulled and not file:is_valid() then
			warn("Diffview is still loading this file. Try again when both sides are visible.")
			return
		end
	end
	if vim.fn.executable(executable) ~= 1 then
		warn("Araxis Merge CLI was not found at " .. executable)
		return
	end

	local directory = vim.fn.tempname() .. "-araxis"
	local function cleanup()
		vim.fn.delete(directory, "rf")
	end
	local success, err = pcall(function()
		vim.fn.mkdir(directory, "p", 448) -- Private directory (0700).
		local left_path = directory .. "/left-" .. (left.basename or "file.txt")
		local right_path = directory .. "/right-" .. (right.basename or "file.txt")
		snapshot(left, left_path)
		snapshot(right, right_path)
		vim.system({
			executable,
			"-wait",
			"-readonly",
			"-title1:Diffview Left — " .. (left.path or ""),
			"-title2:Diffview Right — " .. (right.path or ""),
			left_path,
			right_path,
		}, { text = true }, vim.schedule_wrap(function(result)
			cleanup()
			-- Araxis returns 0 for identical files and 1 for differences.
			if result.code ~= 0 and (result.code ~= 1 or vim.trim(result.stderr or "") ~= "") then
				warn("Araxis failed: " .. vim.trim(result.stderr or "") .. " (exit " .. result.code .. ")")
			end
		end))
	end)
	if not success then
		cleanup()
		warn(tostring(err))
	end
end

return M
