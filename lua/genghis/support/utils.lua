local M = {}
--------------------------------------------------------------------------------

---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
---@param opts? table
function M.notify(msg, level, opts)
	local successNotify = require("genghis.config").config.successNotifications
	if not level then level = "info" end
	if level == "info" and not successNotify then return end
	if not opts then opts = {} end

	opts.title = opts.title and "Genghis: " .. opts.title or "Genghis"
	opts.ft = "text" -- prevent `~` from creating strikethroughs in `snacks.notifier`
	vim.notify(msg, vim.log.levels[level:upper()], opts)
end

---@param oldFilePath string
---@param newFilePath string
function M.moveFileConsideringPartition(oldFilePath, newFilePath)
	local renamed, _ = vim.uv.fs_rename(oldFilePath, newFilePath)
	if renamed then return true end

	---try `fs_copyfile` to support moving across partitions
	local copied, copiedError = vim.uv.fs_copyfile(oldFilePath, newFilePath)
	if copied then
		local deleted, deletedError = vim.uv.fs_unlink(oldFilePath)
		if deleted then
			return true
		else
			M.notify(("Failed to delete %q: %q"):format(oldFilePath, deletedError), "error")
			return false
		end
	else
		local msg = ("Failed to copy %q to %q: %q"):format(oldFilePath, newFilePath, copiedError)
		M.notify(msg, "error")
		return false
	end
end

--------------------------------------------------------------------------------
return M
