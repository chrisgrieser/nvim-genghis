local M = {}
--------------------------------------------------------------------------------

---@return string|string[]
local function setDefaultTrashCmd()
	local osTrashCmd
	local system = vim.uv.os_uname().sysname:lower()
	if system == "darwin" then osTrashCmd = "trash" end
	if system:find("windows") then osTrashCmd = "trash" end
	if system:find("linux") then osTrashCmd = { "gio", "trash" } end
	assert(osTrashCmd, "Unknown operating system. Please provide a custom `trashCmd`.")
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
