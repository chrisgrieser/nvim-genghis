local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify("nvim-genghis requires at least nvim 0.10.", vim.log.levels.WARN)
	return
end
--------------------------------------------------------------------------------

local M = {}

---@param userConfig? Genghis.config
function M.setup(userConfig) require("genghis.config").setup(userConfig) end

setmetatable(M, {
	__index = function(_, key)
		return function(...)
			local module = vim.startswith(key, "copy") and "copy" or "file"
			require("genghis.operations." .. module)[key](...)
		end
	end,
})

--------------------------------------------------------------------------------
return M
