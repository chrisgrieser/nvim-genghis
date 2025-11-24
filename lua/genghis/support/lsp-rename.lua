local M = {}

--------------------------------------------------------------------------------

---Requests a 'workspace/willRenameFiles' on any running LSP client, that supports it
---SOURCE https://github.com/LazyVim/LazyVim/blob/ac092289f506052cfdd1879f462be05075fe3081/lua/lazyvim/util/lsp.lua#L99-L119
---@param fromName string
---@param toName string
function M.willRename(fromName, toName)
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
function M.supported()
	local clients = vim.lsp.get_clients { bufnr = 0 }
	for _, client in ipairs(clients) do
		if client:supports_method("workspace/willRenameFiles") then return true end
	end
	return false
end

--------------------------------------------------------------------------------
return M
