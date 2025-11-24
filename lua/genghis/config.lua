local M = {}
--------------------------------------------------------------------------------

---@class Genghis.config
local defaultConfig = {
	fileOperations = {
		-- automatically keep the extension when no file extension is given
		-- (everything after the first non-leading dot is treated as the extension)
		autoAddExt = true,

		trashCmd = function() ---@type fun(): string|string[]
			if jit.os == "OSX" then return "trash" end -- builtin since macOS 14
			if jit.os == "Windows" then return "trash" end
			if jit.os == "Linux" then return { "gio", "trash" } end
			return "trash-cli"
		end,
	},

	navigation = {
		onlySameExtAsCurrentFile = false,
		ignoreDotfiles = true,
		ignoreExt = { "png", "svg", "webp", "jpg", "jpeg", "gif", "pdf", "zip" },
		ignoreFilesWithName = { ".DS_Store" },
	},

	successNotifications = true,

	icons = { -- set an icon to empty string to disable it
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

	-- DEPRECATION (2025-11-24)
	---@diagnostic disable: undefined-field
	if M.config.trashCmd then
		M.config.fileOperations.trashCmd = M.config.trashCmd
		local notify = require("genghis.support.utils").notify
		notify("config `.trashCmd` is deprecated, use `.fileOperations.trashCmd` instead.", "warn")
	end
	---@diagnostic enable: undefined-field
end

--------------------------------------------------------------------------------
return M
