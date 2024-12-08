local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify("nvim-genghis requires at least nvim 0.10.", vim.log.levels.WARN)
	return
end
--------------------------------------------------------------------------------

local M = {}

---@param userConfig? Genghis.config
function M.setup(userConfig) require("genghis.config").setup(userConfig) end

vim.api.nvim_create_user_command("Genghis", function(ctx) M[ctx.args]() end, {
	nargs = 1,
	complete = function(query)
		local allOps = {}
		vim.list_extend(allOps, vim.tbl_keys(require("genghis.operations.file")))
		vim.list_extend(allOps, vim.tbl_keys(require("genghis.operations.copy")))
		vim.list_extend(allOps, vim.tbl_keys(require("genghis.operations.other")))
		return vim.tbl_filter(function(op) return op:lower():find(query, nil, true) end, allOps)
	end,
})

-- redirect to to the correct module
setmetatable(M, {
	__index = function(_, key)
		return function(...)
			local module = vim.startswith(key, "copy") and "copy" or "file"
			if key == "chmodx" or key == "trashFile" then module = "other" end
			require("genghis.operations." .. module)[key](...)
		end
	end,
})

--------------------------------------------------------------------------------
return M
