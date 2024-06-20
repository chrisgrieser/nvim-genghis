local M = {}
--------------------------------------------------------------------------------

---@class Genghis.config
local defaultConfig = {
	trashCmd = nil,
}

M.config = defaultConfig

---@param userConfig? Genghis.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
