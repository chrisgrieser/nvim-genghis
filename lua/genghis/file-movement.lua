local M = {}

local u = require("genghis.utils")
--------------------------------------------------------------------------------

---Requests a 'workspace/willRenameFiles' on any running LSP client, that supports it
---stolen from https://github.com/LazyVim/LazyVim/blob/fecc5faca25c209ed62e3658dd63731e26c0c643/lua/lazyvim/util/init.lua#L304
---@param fromName string
---@param toName string
function M.onRename(fromName, toName)
	local clients = vim.lsp.get_active_clients { bufnr = 0 }
	for _, client in ipairs(clients) do
		if client:supports_method("workspace/willRenameFiles") then
			local resp = client.request_sync("workspace/willRenameFiles", {
				files = {
					{ oldUri = vim.uri_from_fname(fromName), newUri = vim.uri_from_fname(toName) },
				},
			}, 1000)
			if resp and resp.result ~= nil then
				vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
			end
		end
	end
end

---@nodiscard
---@return boolean
function M.lspSupportsRenaming()
	-- INFO `client:supports_method()` seems to always return true, whatever is
	-- supplied as argument. This does not affect `onRename`, but here we need to
	-- check for the server_capabilities to properly identify whether our LSP
	-- supports renaming or not.
	-- TODO investigate if `client:supports_method()` works in nvim 0.10 or later
	local clients = vim.lsp.get_active_clients { bufnr = 0 }
	for _, client in ipairs(clients) do
		local workspaceCap = client.server_capabilities.workspace
		local supports = workspaceCap and workspaceCap.fileOperations and workspaceCap.fileOperations.willRename
		if supports then return true end
	end
	return false
end

---use instead of fs_rename to support moving across partitions
---@param oldFilePath string
---@param newFilePath string
function M.moveFile(oldFilePath, newFilePath)
	local copied, copiedError = vim.loop.fs_copyfile(oldFilePath, newFilePath)
	if copied then
		local deleted, deletedError = vim.loop.fs_unlink(oldFilePath)
		if deleted then
			return true
		else
			u.notify(("Failed to delete %q: %q"):format(oldFilePath, deletedError), "error")
			return false
		end
	else
		u.notify(("Failed to move %q to %q: %q"):format(oldFilePath, newFilePath, copiedError), "error")
		return false
	end
end

--------------------------------------------------------------------------------
return M
