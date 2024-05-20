local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify("nvim-genghis requires at least nvim 0.10.", vim.log.levels.WARN)
	return
end

--------------------------------------------------------------------------------
local M = {}

local mv = require("genghis.file-movement")
local u = require("genghis.utils")

local fn = vim.fn
local cmd = vim.cmd
local osPathSep = package.config:sub(1, 1)
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
	local lspSupportsRenaming = mv.lspSupportsRenaming()

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
		promptStr = lspSupportsRenaming and "Rename File & Update Imports:" or "Rename File to:"
		prefill = oldNameNoExt
	elseif op == "move-rename" then
		promptStr = lspSupportsRenaming and "Move-Rename File & Update Imports:"
			or "Move & Rename File to:"
		prefill = dir .. osPathSep
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
		local hasPath = newName:find(osPathSep)
		if hasPath then
			local newFolder = vim.fs.dirname(newName)
			fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local extProvided = newName:find(".%.[^/]*$") -- non-leading dot to not include dotfiles without extension
		if not extProvided then newName = newName .. oldExt end
		local newFilePath = (op == "move-rename") and newName or dir .. osPathSep .. newName

		if u.fileExists(newFilePath) then
			u.notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		cmd.update()
		if op == "duplicate" then
			local success = vim.uv.fs_copyfile(oldFilePath, newFilePath)
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
				if lspSupportsRenaming then vim.cmd.wall() end
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
	local curFilePath = vim.api.nvim_buf_get_name(0)
	local parentOfCurFile = vim.fs.dirname(curFilePath) .. osPathSep
	local filename = vim.fs.basename(curFilePath)
	local lspSupportsRenaming = mv.lspSupportsRenaming()
	local cwd = vim.uv.cwd() .. osPathSep

	-- determine destinations in cwd
	local foldersInCwd = vim.fs.find(function(name, path)
		local fullPath = path .. osPathSep .. name .. osPathSep
		local relative_path = osPathSep .. vim.fn.fnamemodify(fullPath, ":~:.")
		local ignoreDirs = relative_path:find("/%.git/")
			or relative_path:find("%.app/") -- macos pseudo-folders
			or relative_path:find("/node_modules/")
			or relative_path:find("/%.venv/")
			or relative_path:find("/%.") -- hidden folders
			or fullPath == parentOfCurFile
		return not ignoreDirs
	end, { type = "directory", limit = math.huge })

	-- sort by modification time
	table.sort(foldersInCwd, function(a, b)
		local aMtime = vim.uv.fs_stat(a).mtime.sec
		local bMtime = vim.uv.fs_stat(b).mtime.sec
		return aMtime > bMtime
	end)
	-- insert cwd at bottom, since modification of is likely due to subfolders
	if cwd ~= parentOfCurFile then table.insert(foldersInCwd, cwd) end

	-- prompt user and move
	local promptStr = "Choose Destination Folder"
	if lspSupportsRenaming then promptStr = promptStr .. " (with updated imports)" end
	vim.ui.select(foldersInCwd, {
		prompt = promptStr,
		kind = "genghis.moveToFolderInCwd",
		format_item = function(path) return path:sub(#cwd) end, -- only relative path
	}, function(destination)
		if not destination then return end
		local newFilePath = destination .. osPathSep .. filename

		-- GUARD
		if u.fileExists(newFilePath) then
			u.notify(("File %q already exists at %q."):format(filename, destination), "error")
			return
		end

		mv.sendWillRenameToLsp(curFilePath, newFilePath)
		local success = mv.moveFile(curFilePath, newFilePath)
		if success then
			cmd.edit(newFilePath)
			u.bwipeout("#")
			local msg = ("Moved %q to %q"):format(filename, destination)
			local append = lspSupportsRenaming and " and updated imports." or "."
			u.notify(msg .. append)
			if lspSupportsRenaming then vim.cmd.wall() end
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

-- DOCS for the modifiers
-- https://neovim.io/doc/user/builtin.html#expand()
-- https://neovim.io/doc/user/cmdline.html#filename-modifiers
function M.copyFilepath() copyOp("%:p") end
function M.copyFilepathWithTilde() copyOp("%:~") end
function M.copyFilename() copyOp("%:t") end
function M.copyRelativePath() copyOp("%:.") end
function M.copyDirectoryPath() copyOp("%:p:h") end
function M.copyRelativeDirectoryPath() copyOp("%:.:h") end

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

---@param opts? { trashCmd: string }
function M.trashFile(opts)
	local userCmd = opts and opts.trashCmd
	local defaultCmd
	if fn.has("mac") == 1 then defaultCmd = "trash" end
	if fn.has("linux") == 1 then defaultCmd = "trash" end
	if fn.has("win32") == 1 then defaultCmd = "gio trash" end
	local trashCmd = userCmd or defaultCmd
	assert(defaultCmd, "Unknown operating system & no custom trashCmd provided.")

	local trashArgs = vim.split(trashCmd, " ")
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	table.insert(trashArgs, oldFilePath)

	cmd("silent! update")
	local oldName = vim.fs.basename(oldFilePath)
	local result = vim.system(trashArgs):wait()
	if result.code == 0 then
		u.bwipeout()
		u.notify(("%q deleted"):format(oldName))
	else
		local outmsg = (result.stdout or "") .. (result.stderr or "")
		u.notify(("Trashing %q failed: " .. outmsg):format(oldName), "error")
	end
end

--------------------------------------------------------------------------------
return M
