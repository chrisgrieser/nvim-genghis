local M = {}

--------------------------------------------------------------------------------

---Requests a 'workspace/willRenameFiles' on any running LSP client, that supports it
---SOURCE https://github.com/LazyVim/LazyVim/blob/ac092289f506052cfdd1879f462be05075fe3081/lua/lazyvim/util/lsp.lua#L99-L119
---@param fromName string
---@param toName string
function M.sendWillRenameToLsp(fromName, toName)
	local clients = vim.lsp.get_clients { bufnr = 0 }
	for _, client in ipairs(clients) do
		if client:supports_method("workspace/willRenameFiles") then
			local response = client:request_sync("workspace/willRenameFiles", {
				files = {
					{ oldUri = vim.uri_from_fname(fromName), newUri = vim.uri_from_fname(toName) },
				},
			}, 1000, 0)
			if response and response.result ~= nil then
				vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
			end
		end
	end
end

---@nodiscard
---@return boolean
function M.lspSupportsRenaming()
	local clients = vim.lsp.get_clients { bufnr = 0 }
	for _, client in ipairs(clients) do
		if client:supports_method("workspace/willRenameFiles") then return true end
	end
	return false
end

---@param oldFilePath string
---@param newFilePath string
function M.moveFile(oldFilePath, newFilePath)
	local u = require("genghis.support.utils")

	local renamed, _ = vim.uv.fs_rename(oldFilePath, newFilePath)
	if renamed then return true end

	---try `fs_copyfile` to support moving across partitions
	local copied, copiedError = vim.uv.fs_copyfile(oldFilePath, newFilePath)
	if copied then
		local deleted, deletedError = vim.uv.fs_unlink(oldFilePath)
		if deleted then
			return true
		else
			u.notify(("Failed to delete %q: %q"):format(oldFilePath, deletedError), "error")
			return false
		end
	else
		local msg = ("Failed to copy %q to %q: %q"):format(oldFilePath, newFilePath, copiedError)
		u.notify(msg, "error")
		return false
	end
end

--------------------------------------------------------------------------------
return M
