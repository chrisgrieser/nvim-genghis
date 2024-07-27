local M = {}
--------------------------------------------------------------------------------

local backdropName = "GenghisBackdrop"

---@param referenceBuf number Reference buffer, when that buffer is closed, the backdrop will be closed too
---@param referenceZindex? number zindex of the reference window, where the backdrop should be placed below
function M.new(referenceBuf, referenceZindex)
	local config = require("genghis.config").config
	if not config.backdrop.enabled then return end
	local blend = config.backdrop.blend

	-- `DressingInput` has a zindex of 49: https://github.com/stevearc/dressing.nvim/blob/e3714c8049b2243e792492c4149e4cc395c68eb9/lua/dressing/input.lua#L369
	-- `DressingSelect` has a zindex of 150: https://github.com/stevearc/dressing.nvim/blob/e3714c8049b2243e792492c4149e4cc395c68eb9/lua/dressing/select/builtin.lua#L96
	-- `nivm-notify` apparently does not set a zindex, so it uses the default value
	-- of `nvim_open_win`, which is 50: https://neovim.io/doc/user/api.html#nvim_open_win()
	-- satellite.nvim has (by default) 40, backdrop should be above -- https://github.com/lewis6991/satellite.nvim?tab=readme-ov-file#usage
	if not referenceZindex then referenceZindex = 49 end

	local bufnr = vim.api.nvim_create_buf(false, true)
	local winnr = vim.api.nvim_open_win(bufnr, false, {
		relative = "editor",
		row = 0,
		col = 0,
		width = vim.o.columns,
		height = vim.o.lines,
		focusable = false,
		style = "minimal",
		zindex = referenceZindex - 1, -- ensure it's below the reference window
	})
	vim.api.nvim_set_hl(0, backdropName, { bg = "#000000", default = true })
	vim.wo[winnr].winhighlight = "Normal:" .. backdropName
	vim.wo[winnr].winblend = blend
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].filetype = backdropName

	-- close backdrop when the reference buffer is closed
	vim.api.nvim_create_autocmd({ "WinClosed", "BufLeave" }, {
		group = vim.api.nvim_create_augroup(backdropName, { clear = true }),
		once = true,
		buffer = referenceBuf,
		callback = function()
			if vim.api.nvim_win_is_valid(winnr) then vim.api.nvim_win_close(winnr, true) end
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
		end,
	})
end

--------------------------------------------------------------------------------
return M
