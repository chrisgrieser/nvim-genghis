local M = {}
--------------------------------------------------------------------------------

---@class Genghis.config
local defaultConfig = {
	---@type fun(): string|string[]
	trashCmd = function()
		if jit.os == "OSX" then return "trash" end -- builtin since macOS 14
		if jit.os == "Windows" then return "trash" end
		if jit.os == "Linux" then return { "gio", "trash" } end
		return "trash-cli"
	end,

	-- set to empty string to disable
	-- (some icons are only used for notification plugins like `snacks.nvim`)
	icons = {
		chmodx = "󰒃",
		copyFile = "󱉥",
		copyPath = "󰅍",
		duplicate = "",
		file = "󰈔",
		move = "󰪹",
		new = "󰝒",
		nextFile = "󰖽",
		prevFile = "󰖿",
		rename = "󰑕",
		trash = "󰩹",
	},

	navigation = {
		ignoreExt = { "png", "svg", "webp", "jpg", "jpeg", "gif", "pdf", "zip" },
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
