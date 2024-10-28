local M = {}
--------------------------------------------------------------------------------

---@return string|string[]|false
local function setDefaultTrashCmd()
	local osTrashCmd
	if jit.os == "osx" then
		osTrashCmd = "trash"
	elseif jit.os == "Windows" then
		osTrashCmd = "trash"
	elseif jit.os == "Linux" then
		osTrashCmd = { "gio", "trash" }
	else
		return false
	end
	return osTrashCmd
end

---@class Genghis.config
local defaultConfig = {
	backdrop = {
		enabled = true,
		blend = 50,
	},
	-- cli name, default is `trash` on Mac and Windows, and `gio trash` on Linux
	trashCmd = setDefaultTrashCmd(),
}

M.config = defaultConfig

---@param userConfig? Genghis.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
