local M = {}
--------------------------------------------------------------------------------

---@param bufnr? number|"#"|"$"
function M.bwipeout(bufnr)
	bufnr = bufnr and vim.fn.bufnr(bufnr) or 0 ---@diagnostic disable-line: param-type-mismatch
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- https://github.com/neovim/neovim/issues/17735#issuecomment-1068525617
function M.leaveVisualMode()
	local escKey = vim.api.nvim_replace_termcodes("<Esc>", false, true, true)
	vim.api.nvim_feedkeys(escKey, "nx", false)
end

---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
function M.notify(msg, level)
	if not level then level = "info" end
	vim.notify(msg, vim.log.levels[level:upper()], { title = "nvim-genghis" })
end

---@param filepath string
---@return boolean
function M.fileExists(filepath) return vim.loop.fs_stat(filepath) ~= nil end

--------------------------------------------------------------------------------
return M
