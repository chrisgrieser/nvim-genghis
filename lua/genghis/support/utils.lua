local M = {}
--------------------------------------------------------------------------------

---@param bufnr? number|"#"|"$"
function M.bwipeout(bufnr)
	bufnr = bufnr and vim.fn.bufnr(bufnr) or 0
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
---@param opts? table
function M.notify(msg, level, opts)
	if not level then level = "info" end
	if not opts then opts = {} end
	opts.title = opts.title and "Genghis: " .. opts.title or "Genghis"

	-- since nvim-notify does not support the `icon` field that snacks.nvim
	if package.loaded["notify"] then
		opts.title = vim.trim(opts.icon .. opts.title)
		opts.icon = nil
	end

	vim.notify(msg, vim.log.levels[level:upper()], opts)
end

---@nodiscard
---@param filepath string
---@return boolean
function M.fileExists(filepath) return vim.uv.fs_stat(filepath) ~= nil end

--------------------------------------------------------------------------------
return M
