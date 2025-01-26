local M = {}
--------------------------------------------------------------------------------

---@return string|string[]|false
local function setDefaultTrashCmd()
	local osTrashCmd
	if jit.os == "OSX" then
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
	-- cli name, default is `trash` on Mac and Windows, and `gio trash` on Linux
	trashCmd = setDefaultTrashCmd(),

	-- set to empty string to disable
	-- (some icons are only used for notification plugins like `snacks.nvim`)
	icons = {
		chmodx = "󰒃",
		copyPath = "󰅍",
		copyFile = "󱉥",
		duplicate = "",
		file = "󰈔",
		move = "󰪹",
		new = "󰝒",
		rename = "󰑕",
		trash = "󰩹",
	},

	successNotifications = true,
}

M.config = defaultConfig

---@param userConfig? Genghis.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
