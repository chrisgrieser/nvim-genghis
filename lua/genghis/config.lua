local M = {}
--------------------------------------------------------------------------------

---@class Genghis.config
local defaultConfig = {
	trashCmd = function() ---@type fun(): string|string[]
		if jit.os == "OSX" then return "trash" end -- builtin since macOS 14
		if jit.os == "Windows" then return "trash" end
		if jit.os == "Linux" then return { "gio", "trash" } end
		return "trash-cli"
	end,

	fileOperations = {
		-- automatically keep the extension when no file extension is given
		autoAddExt = true,
	},

	navigation = {
		onlySameExtAsCurrentFile = false,
		ignoreDotfiles = true,
		ignoreExt = { "png", "svg", "webp", "jpg", "jpeg", "gif", "pdf", "zip" },
		ignoreFilesWithName = { ".DS_Store" },
	},

	successNotifications = true,

	icons = { -- set to empty string to disable
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
}

M.config = defaultConfig

---@param userConfig? Genghis.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
