local M = {}
local u = require("genghis.support.utils")
--------------------------------------------------------------------------------

---Makes current file executable
function M.chmodx()
	local icons = require("genghis.config").config.icons

	local filename = vim.api.nvim_buf_get_name(0)
	local perm = vim.fn.getfperm(filename)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	vim.fn.setfperm(filename, perm)

	u.notify("Execution Permission granted.", "info", { icon = icons.chmodx })
	vim.cmd.edit() -- reload the file
end

function M.trashFile()
	vim.cmd("silent! update")
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local oldName = vim.fs.basename(oldFilePath)
	local icons = require("genghis.config").config.icons

	-- execute the trash command
	local trashCmd = require("genghis.config").config.trashCmd
	if not trashCmd then
		u.notify("Unknown operating system. Please provide a custom `trashCmd`.", "warn")
		return
	end
	if type(trashCmd) == "string" then trashCmd = { trashCmd } end
	table.insert(trashCmd, oldFilePath)
	local result = vim.system(trashCmd):wait()

	-- handle the result
	if result.code == 0 then
		u.bwipeout()
		u.notify(("%q put into trash."):format(oldName), "info", { icon = icons.trash })
	else
		local outmsg = (result.stdout or "") .. (result.stderr or "")
		u.notify(("Trashing %q failed: " .. outmsg):format(oldName), "error")
	end
end

--------------------------------------------------------------------------------
return M
