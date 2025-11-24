---@param oldFilePath string
---@param newFilePath string
---@return boolean success
return function(oldFilePath, newFilePath)
	local renamed, _ = vim.uv.fs_rename(oldFilePath, newFilePath)
	if renamed then return true end

	local notify = require("genghis.support.notify")

	-- try `fs_copyfile` to support moving across partitions
	local copied, copiedError = vim.uv.fs_copyfile(oldFilePath, newFilePath)
	if copied then
		local deleted, deletedError = vim.uv.fs_unlink(oldFilePath)
		if deleted then
			return true
		else
			notify(("Failed to delete %q: %q"):format(oldFilePath, deletedError), "error")
			return false
		end
	else
		local msg = ("Failed to copy %q to %q: %q"):format(oldFilePath, newFilePath, copiedError)
		notify(msg, "error")
		return false
	end
end
