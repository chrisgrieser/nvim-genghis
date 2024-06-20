local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify("nvim-genghis requires at least nvim 0.10.", vim.log.levels.WARN)
	return
end
--------------------------------------------------------------------------------

local M = {}

-- redirect to `operations.copy` or `operations.file`
setmetatable(M, {
	__index = function(_, key)
		return function(...)
			if key == "setup" then
				require("genghis.config").setup(...)
				return
			end

			local module = vim.startswith(key, "copy") and "copy" or "file"
			require("genghis.operations." .. module)[key](...)
		end
	end,
})

--------------------------------------------------------------------------------
return M
