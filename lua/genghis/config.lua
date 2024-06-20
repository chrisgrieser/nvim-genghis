local M = {}
--------------------------------------------------------------------------------

---@class Genghis.config
local defaultConfig = {
	backdrop = {
		enabled = true,
		blend = 50,
	},
	-- cli name, default is `trash` on Mac and Windows, and `gio trash` on Linux
	trashCmd = nil,
}

M.config = defaultConfig

---@param userConfig? Genghis.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
