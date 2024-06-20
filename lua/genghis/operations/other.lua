local M = {}
local u = require("genghis.support.utils")
--------------------------------------------------------------------------------

---Makes current file executable
function M.chmodx()
	local filename = vim.api.nvim_buf_get_name(0)
	local perm = vim.fn.getfperm(filename)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	vim.fn.setfperm(filename, perm)
	u.notify("Execution Permission granted.")
	vim.cmd.edit()
end

function M.trashFile(opts)
	---DEPRECATION
	if opts then
		u.notify("The `trashCmd` option has been moved to the setup call.", "warn")
		return
	end

	-- user-provided trashCmd or os-specific default
	local trashCmd = require("genghis.config").config.trashCmd
	if not trashCmd then
		local system = vim.uv.os_uname().sysname:lower()
		local defaultCmd
		if system == "darwin" then defaultCmd = "trash" end
		if system:find("windows") then defaultCmd = "trash" end
		if system:find("linux") then defaultCmd = "gio trash" end
		assert(defaultCmd, "Unknown operating system. Please provide a custom `trashCmd`.")
		trashCmd = defaultCmd
	end

	local trashArgs = vim.split(trashCmd, " ")
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	table.insert(trashArgs, oldFilePath)

	vim.cmd("silent! update")
	local oldName = vim.fs.basename(oldFilePath)
	local result = vim.system(trashArgs):wait()
	if result.code == 0 then
		u.bwipeout()
		u.notify(("%q deleted."):format(oldName))
	else
		local outmsg = (result.stdout or "") .. (result.stderr or "")
		u.notify(("Trashing %q failed: " .. outmsg):format(oldName), "error")
	end
end

--------------------------------------------------------------------------------
return M
