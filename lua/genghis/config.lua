local M = {}
--------------------------------------------------------------------------------

---@return string|string[]
local function setDefaultTrashCmd()
	local osTrashCmd
	local system = jit.os:lower()
	if system == "mac" or system == "osx" then
		osTrashCmd = "trash"
	elseif system == "windows" then
		osTrashCmd = "trash"
	else
		osTrashCmd = { "gio", "trash" }
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
