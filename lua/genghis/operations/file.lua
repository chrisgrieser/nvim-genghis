local M = {}

local rename = require("genghis.support.lsp-rename")
local u = require("genghis.support.utils")
local pathSep = package.config:sub(1, 1)
--------------------------------------------------------------------------------

---@param op "rename"|"duplicate"|"new"|"new-from-selection"|"move-rename"
local function fileOp(op)
	local origBufNr = vim.api.nvim_get_current_buf()
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local oldName = vim.fs.basename(oldFilePath)
	local dir = vim.fs.dirname(oldFilePath) -- same directory, *not* pwd
	local oldNameNoExt = oldName:gsub("%.%w+$", "")
	local oldExt = vim.fn.expand("%:e")
	if oldExt ~= "" then oldExt = "." .. oldExt end
	local icons = require("genghis.config").config.icons
	local lspSupportsRenaming = rename.lspSupportsRenaming()

	local prevReg
	if op == "new-from-selection" then
		prevReg = vim.fn.getreg("z")
		-- leaves visual mode, needed for '<,'> marks to be set
		vim.cmd.normal { vim.fn.mode(), bang = true }
		vim.cmd([['<,'>delete z]])
	end

	local promptStr, prefill
	if op == "duplicate" then
		promptStr = icons.duplicate .. " Duplicate file as: "
		prefill = oldNameNoExt .. "-1"
	elseif op == "rename" then
		local text = lspSupportsRenaming and "Rename file & update imports:" or "Rename file to:"
		promptStr = icons.rename .. " " .. text
		prefill = oldNameNoExt
	elseif op == "move-rename" then
		local text = lspSupportsRenaming and " Move and rename file & update imports:"
			or " Move & rename file to:"
		promptStr = icons.rename .. " " .. text
		prefill = dir .. pathSep
	elseif op == "new" or op == "new-from-selection" then
		promptStr = icons.new .. " Name for new file: "
		prefill = ""
	end
	promptStr = vim.trim(promptStr) -- in case of empty icon

	vim.ui.input({
		prompt = promptStr,
		default = prefill,
		completion = "dir", -- allows for completion via cmp-omni
	}, function(newName)
		vim.cmd.redraw() -- Clear message area from ui.input prompt
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
			if op == "new-from-selection" then
				vim.cmd.undo() -- undo deletion
				vim.fn.setreg("z", prevReg) -- restore register content
			end
			if invalidName or emptyInput then
				u.notify("Invalid filename.", "error")
			elseif sameName then
				u.notify("Cannot use the same filename.", "warn")
			end
			return
		end

		-- DETERMINE PATH AND EXTENSION
		local hasPath = newName:find(pathSep)
		if hasPath then
			local newFolder = vim.fs.dirname(newName)
			vim.fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local extProvided = newName:find(".%.[^/]*$") -- non-leading dot to not include dotfiles without extension
		if not extProvided then newName = newName .. oldExt end
		local newFilePath = (op == "move-rename") and newName or dir .. pathSep .. newName

		if vim.uv.fs_stat(newFilePath) ~= nil then
			u.notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		vim.cmd.update()
		if op == "duplicate" then
			local success = vim.uv.fs_copyfile(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				local msg = ("Duplicated %q as %q."):format(oldName, newName)
				u.notify(msg, "info", { icon = icons.duplicate })
			end
		elseif op == "rename" or op == "move-rename" then
			rename.sendWillRenameToLsp(oldFilePath, newFilePath)
			local success = u.moveFileConsideringPartition(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				vim.api.nvim_buf_delete(origBufNr, { force = true })
				local msg = ("Renamed %q to %q."):format(oldName, newName)
				u.notify(msg, "info", { icon = icons.rename })
				if lspSupportsRenaming then vim.cmd.wall() end
			end
		elseif op == "new" or op == "new-from-selection" then
			vim.cmd.edit(newFilePath)
			if op == "new-from-selection" then
				vim.cmd("put z") -- cmd.put("z") does not work
				vim.fn.setreg("z", prevReg) -- restore register content
			end
			vim.cmd.write(newFilePath)
		end
	end)
end

function M.renameFile() fileOp("rename") end
function M.moveAndRenameFile() fileOp("move-rename") end
function M.duplicateFile() fileOp("duplicate") end
function M.createNewFile() fileOp("new") end
function M.moveSelectionToNewFile() fileOp("new-from-selection") end

--------------------------------------------------------------------------------

function M.moveToFolderInCwd()
	local curFilePath = vim.api.nvim_buf_get_name(0)
	local parentOfCurFile = vim.fs.dirname(curFilePath)
	local filename = vim.fs.basename(curFilePath)
	local lspSupportsRenaming = rename.lspSupportsRenaming()
	local cwd = vim.uv.cwd()
	local icons = require("genghis.config").config.icons
	local origBufNr = vim.api.nvim_get_current_buf()

	-- determine destinations in cwd
	local foldersInCwd = vim.fs.find(function(name, path)
		local absPath = vim.fs.joinpath(path, name)
		local relPath = absPath:sub(#cwd + 1) .. pathSep
		local ignoreDirs = absPath == parentOfCurFile
			or relPath:find("/node_modules/") -- js/ts
			or relPath:find("/typings/") -- python
			or relPath:find("%.app/") -- macos pseudo-folders
			or relPath:find("/%.") -- hidden folders
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
	local promptStr = icons.new .. " Choose destination folder"
	if lspSupportsRenaming then promptStr = promptStr .. " (with updated imports)" end
	vim.ui.select(foldersInCwd, {
		prompt = promptStr,
		kind = "genghis.moveToFolderInCwd",
		format_item = function(path)
			local relPath = path:sub(#cwd + 1)
			return (relPath == "" and "/" or relPath)
		end,
	}, function(destination)
		if not destination then return end
		local newFilePath = vim.fs.joinpath(destination, filename)

		-- GUARD
		if vim.uv.fs_stat(newFilePath) ~= nil then
			u.notify(("File %q already exists at %q."):format(filename, destination), "error")
			return
		end

		rename.sendWillRenameToLsp(curFilePath, newFilePath)
		local success = u.moveFileConsideringPartition(curFilePath, newFilePath)
		if success then
			vim.cmd.edit(newFilePath)
			vim.api.nvim_buf_delete(origBufNr, { force = true })
			local msg = ("Moved %q to %q"):format(filename, destination)
			local append = lspSupportsRenaming and " and updated imports." or "."
			u.notify(msg .. append, "info", { icon = icons.move })
			if lspSupportsRenaming then vim.cmd.wall() end
		end
	end)
end

function M.chmodx()
	local icons = require("genghis.config").config.icons

	local filepath = vim.api.nvim_buf_get_name(0)
	local perm = vim.fn.getfperm(filepath)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	vim.fn.setfperm(filepath, perm)

	u.notify("Permission +x granted.", "info", { icon = icons.chmodx })
	vim.cmd.edit() -- reload the file
end

function M.trashFile()
	vim.cmd("silent! update")
	local filepath = vim.api.nvim_buf_get_name(0)
	local filename = vim.fs.basename(filepath)
	local icon = require("genghis.config").config.icons.trash
	local trashCmd = require("genghis.config").config.trashCmd

	-- execute the trash command
	if type(trashCmd) ~= "function" then
		-- DEPRECATION (2025-03-29)
		u.notify("`trashCmd` now expects a function, see the README.", "warn")
		return
	end
	local cmd = trashCmd()
	if type(cmd) ~= "table" then cmd = { cmd } end
	table.insert(cmd, filepath)
	local out = vim.system(cmd):wait()

	-- handle the result
	if out.code == 0 then
		vim.api.nvim_buf_delete(0, { force = true })
		u.notify(("%q moved to trash."):format(filename), "info", { icon = icon })
	else
		local outmsg = (out.stdout or "") .. (out.stderr or "")
		u.notify(("Trashing %q failed: %s"):format(filename, outmsg), "error")
	end
end

function M.showInSystemExplorer()
	if jit.os ~= "OSX" then
		u.notify("Currently only available on macOS.", "warn")
		return
	end

	local out = vim.system({ "open", "-R", vim.api.nvim_buf_get_name(0) }):wait()
	if out.code ~= 0 then
		local icon = require("genghis.config").config.icons.file
		u.notify("Failed: " .. out.stderr, "error", { icon = icon })
	end
end
--------------------------------------------------------------------------------
return M
