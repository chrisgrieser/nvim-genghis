local M = {}
--------------------------------------------------------------------------------

---@param bufnr? number|"#"|"$"
function M.bwipeout(bufnr)
	bufnr = bufnr and vim.fn.bufnr(bufnr) or 0
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
function M.notify(msg, level)
	if not level then level = "info" end
	vim.notify(msg, vim.log.levels[level:upper()], { title = "nvim-genghis" })
end

---@nodiscard
---@param filepath string
---@return boolean
function M.fileExists(filepath) return vim.uv.fs_stat(filepath) ~= nil end

--------------------------------------------------------------------------------
return M
