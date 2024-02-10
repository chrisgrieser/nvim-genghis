local M = {}

local fn = vim.fn
local cmd = vim.cmd

local mv = require("genghis.file-movement")
local u = require("genghis.utils")

--------------------------------------------------------------------------------

---Performing common file operation tasks
---@param op "rename"|"duplicate"|"new"|"newFromSel"|"move-rename"
local function fileOp(op)
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local oldName = vim.fs.basename(oldFilePath)
	local dir = vim.fs.dirname(oldFilePath) -- same directory, *not* pwd
	local oldNameNoExt = oldName:gsub("%.%w+$", "")
	local oldExt = fn.expand("%:e")
	if oldExt ~= "" then oldExt = "." .. oldExt end

	local prevReg
	if op == "newFromSel" then
		prevReg = fn.getreg("z")
		u.leaveVisualMode()
		cmd([['<,'>delete z]])
	end

	local promptStr, prefill
	if op == "duplicate" then
		promptStr = "Duplicate File as: "
		prefill = oldNameNoExt .. "-1"
	elseif op == "rename" then
		promptStr = mv.lspSupportsRenaming() and "Rename File & Update Imports:" or "Rename File to:"
		prefill = oldNameNoExt
	elseif op == "move-rename" then
		promptStr = mv.lspSupportsRenaming() and "Move-Rename File & Update Imports:"
			or "Move & Rename File to:"
		prefill = dir .. "/"
	elseif op == "new" or op == "newFromSel" then
		promptStr = "Name for New File: "
		prefill = ""
	end

	vim.ui.input({
		prompt = promptStr,
		default = prefill,
		completion = "dir", -- allows for completion via cmp-omni
	}, function(newName)
		cmd.redraw() -- Clear message area from ui.input prompt
		if not newName then return end -- input has been canceled

		if op == "move-rename" and newName:find("/$") then newName = newName .. oldName end
		if op == "new" and newName == "" then newName = "Untitled" end

		-- GUARD Validate filename
		local invalidName = newName:find("^%s+$")
			or newName:find("[\\:]")
			or (newName:find("^/") and not op == "move-rename")
		local sameName = newName == oldName
		local emptyInput = newName == ""

		if invalidName or sameName or emptyInput then
			if op == "newFromSel" then
				cmd.undo() -- undo deletion
				fn.setreg("z", prevReg) -- restore register content
			end
			if invalidName or emptyInput then
				u.notify("Invalid filename.", "error")
			elseif sameName then
				u.notify("Cannot use the same filename.", "warn")
			end
			return
		end

		-- DETERMINE PATH AND EXTENSION
		local hasPath = newName:find("/")
		if hasPath then
			local newFolder = vim.fs.dirname(newName)
			fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local extProvided = newName:find(".%.[^/]*$") -- non-leading dot to not include dotfiles without extension
		if not extProvided then newName = newName .. oldExt end
		local newFilePath = (op == "move-rename") and newName or dir .. "/" .. newName

		if u.fileExists(newFilePath) then
			u.notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		cmd.update()
		if op == "duplicate" then
			local success = vim.loop.fs_copyfile(oldFilePath, newFilePath)
			if success then
				cmd.edit(newFilePath)
				u.notify(("Duplicated %q as %q."):format(oldName, newName))
			end
		elseif op == "rename" or op == "move-rename" then
			mv.sendWillRenameToLsp(oldFilePath, newFilePath)
			local success = mv.moveFile(oldFilePath, newFilePath)
			if success then
				cmd.edit(newFilePath)
				u.bwipeout("#")
				u.notify(("Renamed %q to %q."):format(oldName, newName))
			end
		elseif op == "new" or op == "newFromSel" then
			cmd.edit(newFilePath)
			if op == "newFromSel" then
				cmd("put z") -- cmd.put("z") does not work
				fn.setreg("z", prevReg) -- restore register content
			end
			cmd.write(newFilePath)
		end
	end)
end

function M.renameFile() fileOp("rename") end
function M.moveAndRenameFile() fileOp("move-rename") end
function M.duplicateFile() fileOp("duplicate") end
function M.createNewFile() fileOp("new") end
function M.moveSelectionToNewFile() fileOp("newFromSel") end

function M.moveToFolderInCwd()
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local currentFolderOfFile = vim.fs.dirname(oldFilePath) .. "/"
	local filename = vim.fs.basename(oldFilePath)
	local supportsImportUpdates = mv.lspSupportsRenaming()

	-- determine destinations in cwd
	local subfoldersOfCwd = vim.fs.find(function(name, path)
		local fullPath = path .. "/" .. name .. "/"
		local ignoreDirs = fullPath:find("/%.git/")
			or fullPath:find("%.app/") -- macos pseudo-folders
			or fullPath:find("/node_modules/")
			or fullPath:find("/%.venv/")
			or fullPath == currentFolderOfFile
		return not ignoreDirs
	end, { type = "directory", limit = math.huge })

	-- sort by modification time
	table.sort(subfoldersOfCwd, function(a, b)
		local aMtime = vim.loop.fs_stat(a).mtime.sec
		local bMtime = vim.loop.fs_stat(b).mtime.sec
		return aMtime > bMtime
	end)

	-- prompt user and move
	local promptStr = "Choose Destination Folder"
	if supportsImportUpdates then promptStr = promptStr .. " (with updated imports)" end
	vim.ui.select(subfoldersOfCwd, {
		prompt = promptStr,
		kind = "genghis.moveToFolderInCwd",
		format_item = function(path) return path:sub(#vim.loop.cwd() + 2) end, -- only relative path
	}, function(destination)
		if not destination then return end
		local newFilePath = destination .. "/" .. filename

		-- GUARD
		if u.fileExists(newFilePath) then
			u.notify(("File %q already exists at %q."):format(filename, destination), "error")
			return
		end

		mv.sendWillRenameToLsp(oldFilePath, newFilePath)
		local success = mv.moveFile(oldFilePath, newFilePath)
		if success then
			cmd.edit(newFilePath)
			u.bwipeout("#")
			local msg = ("Moved %q to %q"):format(filename, destination)
			local append = supportsImportUpdates and " and updated imports." or "."
			u.notify(msg + append)
		end
	end)
end

--------------------------------------------------------------------------------

---copying file information
---@param expandOperation string
local function copyOp(expandOperation)
	local reg = '"'
	local clipboardOpt = vim.opt.clipboard:get()
	local useSystemClipb = vim.g.genghis_use_systemclipboard
		or (#clipboardOpt > 0 and clipboardOpt[1]:find("unnamed"))
	if useSystemClipb then reg = "+" end

	local toCopy = fn.expand(expandOperation)
	fn.setreg(reg, toCopy)
	vim.notify(toCopy, vim.log.levels.INFO, { title = "Copied" })
end

-- DOCS for the available modifiers: https://neovim.io/doc/user/builtin.html#expand()
function M.copyFilepath() copyOp("%:p") end
function M.copyFilename() copyOp("%:t") end
function M.copyRelativePath() copyOp("%:~:.") end
function M.copyDirectoryPath() copyOp("%:p:h") end
function M.copyRelativeDirectoryPath() copyOp("%:~:.:h") end

--------------------------------------------------------------------------------

---Makes current file executable
function M.chmodx()
	local filename = vim.api.nvim_buf_get_name(0)
	local perm = fn.getfperm(filename)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	fn.setfperm(filename, perm)
	u.notify("Execution Permission granted.")
	cmd.edit()
end

---@param opts? { trashCmd: string}
function M.trashFile(opts)
	if opts == nil then opts = {} end
	local defaultTrashCmds = {
		macos = "trash", -- not installed by default
		windows = "trash", -- not installed by default
		linux = "gio trash",
	}

	cmd("silent! update")

	local system
	if fn.has("mac") == 1 then system = "macos" end
	if fn.has("linux") == 1 then system = "linux" end
	if fn.has("win32") == 1 then system = "windows" end
	local trashCmd = opts.trashCmd or defaultTrashCmds[system]

	-- Use a trash command
	local trashArgs = vim.split(trashCmd, " ")
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	table.insert(trashArgs, oldFilePath)

	local errMsg = ""
	vim.fn.jobstart(trashArgs, {
		detach = true,
		on_stderr = function(_, data) errMsg = errMsg .. (data and table.concat(data, " ")) end,
		on_exit = function(_, rc)
			local oldName = vim.fs.basename(oldFilePath)
			if rc == 0 then
				u.bwipeout()
				u.notify(("%q deleted"):format(oldName))
			else
				u.notify(("Trashing %q failed: " .. errMsg):format(oldName), "error")
			end
		end,
	})
end

--------------------------------------------------------------------------------
return M
