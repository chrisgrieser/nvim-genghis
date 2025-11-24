local M = {}
--------------------------------------------------------------------------------

---@param expandOperation string
local function copyOp(expandOperation)
	local icon = require("genghis.config").config.icons.copyPath

	local register = "+"
	local toCopy = vim.fn.expand(expandOperation)
	vim.fn.setreg(register, toCopy)

	local notify = require("genghis.support.notify")
	notify(toCopy, "info", { title = "Copied", icon = icon })
end

-- DOCS for the modifiers
-- https://neovim.io/doc/user/builtin.html#expand()
-- https://neovim.io/doc/user/cmdline.html#filename-modifiers
function M.copyFilepath() copyOp("%:p") end
function M.copyFilepathWithTilde() copyOp("%:~") end
function M.copyFilename() copyOp("%:t") end
function M.copyRelativePath() copyOp("%:.") end
function M.copyDirectoryPath() copyOp("%:p:h") end
function M.copyRelativeDirectoryPath() copyOp("%:.:h") end

function M.copyFileItself()
	local notify = require("genghis.support.notify")
	if jit.os ~= "OSX" then
		notify("Currently only available on macOS.", "warn")
		return
	end

	local icon = require("genghis.config").config.icons.copyFile
	local path = vim.api.nvim_buf_get_name(0)
	local applescript = 'tell application "Finder" to set the clipboard to '
		.. ("POSIX file %q"):format(path)

	vim.system({ "osascript", "-e", applescript }, {}, function(out)
		if out.code ~= 0 then
			notify("Failed to copy file: " .. out.stderr, "error", { title = "Copy file" })
		else
			notify(vim.fs.basename(path), "info", { title = "Copied file", icon = icon })
		end
	end)
end

--------------------------------------------------------------------------------
return M
