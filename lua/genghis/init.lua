local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify("nvim-genghis requires at least nvim 0.10.", vim.log.levels.WARN)
	return
end
--------------------------------------------------------------------------------

local M = {}

---@param userConfig? Genghis.config
function M.setup(userConfig) require("genghis.config").setup(userConfig) end

---@param direction? "next"|"prev"
function M.navigateToFileInFolder(direction)
	require("genghis.operations.navigation").fileInFolder(direction)
end

-- redirect calls to this module to the respective submodules
setmetatable(M, {
	__index = function(_, key)
		return function(...)
			local warn = require("various-textobjs.utils").warn

			local fileOps = vim.tbl_keys(require("genghis.operations.file"))
			local copyOps = vim.tbl_keys(require("genghis.operations.copy"))

			local module
			if vim.tbl_contains(fileOps, key) then module = "file" end
			if vim.tbl_contains(copyOps, key) then module = "copy" end

			if module then
				require("genghis.operations." .. module)[key](...)
			else
				local msg = ("There is no operation called `%s`.\n\n"):format(key)
					.. "Make sure it exists in the list of operations, and that you haven't misspelled it."
				warn(msg)
			end
		end
	end,
})

--------------------------------------------------------------------------------
return M
