local M = {}
--------------------------------------------------------------------------------

---@param op "rename"|"duplicate"|"new"|"new-from-selection"|"move-rename"
---@param targetDir? string
local function fileOp(op, targetDir)
	local moveFileConsideringPartition = require("genghis.support.move-considering-partition")
	local notify = require("genghis.support.notify")
	local lspRename = require("genghis.support.lsp-rename")

	-- PARAMETERS
	local origBufNr = vim.api.nvim_get_current_buf()
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local oldName = vim.fs.basename(oldFilePath)
	local pathSep = package.config:sub(1, 1)
	if not targetDir then targetDir = vim.fs.dirname(oldFilePath) end

	-- * non-greedy 1st capture, so 2nd capture matches double-extensions (see #60)
	-- * 1st capture requires at least one char, to not match empty string for dotfiles
	local oldNameNoExt, oldExt = oldName:match("(..-)(%.[%w.]*)")
	-- handle files without extension
	if not oldNameNoExt then oldNameNoExt = oldName end
	if not oldExt then oldExt = "" end

	local autoAddExt = require("genghis.config").config.fileOperations.autoAddExt
	local icons = require("genghis.config").config.icons
	local lspSupportsRenaming = lspRename.supported()

	-- PREPARE
	local prevReg
	if op == "new-from-selection" then
		prevReg = vim.fn.getreg("z")
		vim.cmd.normal { vim.fn.mode(), bang = true } -- leave visual mode, so '<,'> marks are set
		vim.cmd([['<,'>delete z]])
	end

	local prompt, prefill
	if op == "duplicate" then
		prompt = icons.duplicate .. " Duplicate file as: "
		prefill = (autoAddExt and oldNameNoExt or oldName) .. "-1"
	elseif op == "rename" then
		local text = lspSupportsRenaming and "Rename file & update imports:" or "Rename file to:"
		prompt = icons.rename .. " " .. text
		prefill = autoAddExt and oldNameNoExt or oldName
	elseif op == "move-rename" then
		local text = lspSupportsRenaming and " Move and rename file & update imports:"
			or " Move & rename file to:"
		prompt = icons.rename .. " " .. text
		prefill = targetDir .. pathSep
	elseif op == "new" or op == "new-from-selection" then
		prompt = icons.new .. " Name for new file: "
		prefill = ""
	end

	-- INPUT
	vim.ui.input({
		prompt = vim.trim(prompt),
		default = prefill,
	}, function(newName)
		vim.cmd.redraw() -- clear message area from vim.ui.input prompt
		if not newName then return end -- input has been canceled

		if op == "move-rename" and vim.endswith(newName, pathSep) then -- user just provided a folder
			newName = newName .. oldName
		elseif (op == "new" or op == "new-from-selection") and newName == "" then
			newName = "Untitled"
		end

		-- GUARD Validate filename
		local invalidName = newName:find("^%s+$")
			or newName:find(":")
			or (vim.startswith(newName, pathSep) and op ~= "move-rename")
		local sameName = newName == oldName
		local emptyInput = newName == ""
		if invalidName or sameName or emptyInput then
			if op == "new-from-selection" then
				vim.cmd.undo() -- undo deletion
				vim.fn.setreg("z", prevReg) -- restore register content
			end
			if invalidName or emptyInput then
				notify("Invalid filename.", "error")
			elseif sameName then
				notify("Cannot use the same filename.", "warn")
			end
			return
		end

		-- DETERMINE PATH AND EXTENSION
		if newName:find(pathSep) then
			local newFolder = vim.fs.dirname(newName)
			vim.fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local userProvidedNoExt = newName:find(".%.[^/]*$") == nil -- non-leading dot to not include dotfiles without extension
		if userProvidedNoExt and autoAddExt then newName = newName .. oldExt end

		local newFilePath = op == "move-rename" and newName or vim.fs.joinpath(targetDir, newName)
		if vim.uv.fs_stat(newFilePath) ~= nil then
			notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		vim.cmd("silent! update")
		if op == "duplicate" then
			local success = vim.uv.fs_copyfile(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				local msg = ("Duplicated %q as %q."):format(oldName, newName)
				notify(msg, "info", { icon = icons.duplicate })
			end
		elseif op == "rename" or op == "move-rename" then
			lspRename.willRename(oldFilePath, newFilePath)
			local success = moveFileConsideringPartition(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				vim.api.nvim_buf_delete(origBufNr, { force = true })
				local msg = ("Renamed %q to %q."):format(oldName, newName)
				notify(msg, "info", { icon = icons.rename })
				if lspSupportsRenaming then vim.cmd.wall() end
			end
		elseif op == "new" or op == "new-from-selection" then
			vim.cmd.edit(newFilePath)
			if op == "new-from-selection" then
				vim.cmd("put z") -- `vim.cmd.put("z")` does not work
				vim.fn.setreg("z", prevReg)
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

---@param op "move-file"|"new-in-folder"
local function folderSelection(op)
	local moveFileConsideringPartition = require("genghis.support.move-considering-partition")
	local notify = require("genghis.support.notify")
	local lspRenaming = require("genghis.support.lsp-rename")

	local curFilePath = vim.api.nvim_buf_get_name(0)
	local parentOfCurFile = vim.fs.dirname(curFilePath)
	local filename = vim.fs.basename(curFilePath)
	local lspSupportsRenaming = lspRenaming.supported()
	local cwd = assert(vim.uv.cwd(), "Could not get current working directory.")
	local icons = require("genghis.config").config.icons
	local origBufNr = vim.api.nvim_get_current_buf()

	-- determine destinations in cwd
	local foldersInCwd = vim.fs.find(function(name, path)
		local absPath = vim.fs.joinpath(path, name)
		local relPath = absPath:sub(#cwd + 1) .. "/" -- not pathSep, since `joinpath` uses `/`
		local ignoreDirs = absPath == parentOfCurFile
			or relPath:find("/node_modules/") -- js/ts
			or relPath:find("/typings/") -- python
			or relPath:find("%.app/") -- macOS pseudo-folders
			or relPath:find("/%.") -- hidden folders
		return not ignoreDirs
	end, { type = "directory", limit = math.huge })

	-- sort by modification time
	table.sort(foldersInCwd, function(a, b)
		local aMtime = vim.uv.fs_stat(a).mtime.sec
		local bMtime = vim.uv.fs_stat(b).mtime.sec
		return aMtime > bMtime
	end)
	-- insert cwd at bottom, since movement is to a subfolder
	if cwd ~= parentOfCurFile then table.insert(foldersInCwd, cwd) end

	-- prompt user and move
	local prompt
	if op == "move-file" then
		prompt = icons.move .. " Move file to"
		if lspSupportsRenaming then prompt = prompt .. " (with updated imports)" end
		prompt = prompt .. ":"
	elseif op == "new-in-folder" then
		prompt = icons.new .. " Folder for new file:"
	end
	vim.ui.select(foldersInCwd, {
		prompt = prompt,
		kind = "genghis.select-folder",
		format_item = function(path)
			local relPath = path:sub(#cwd + 1)
			return (relPath == "" and "/" or relPath)
		end,
	}, function(destination)
		if not destination then return end

		if op == "new-in-folder" then
			fileOp("new", destination)
		elseif op == "move-file" then
			local newFilePath = vim.fs.joinpath(destination, filename)
			if vim.uv.fs_stat(newFilePath) ~= nil then
				notify(("File %q already exists at %q."):format(filename, destination), "error")
				return
			end

			lspRenaming.willRename(curFilePath, newFilePath)
			local success = moveFileConsideringPartition(curFilePath, newFilePath)
			if success then return end

			vim.cmd.edit(newFilePath)
			vim.api.nvim_buf_delete(origBufNr, { force = true })
			local msg = ("Moved %q to %q"):format(filename, destination)
			local append = lspSupportsRenaming and " and updated imports." or "."
			notify(msg .. append, "info", { icon = icons.move })
			if lspSupportsRenaming then vim.cmd.wall() end
		end
	end)
end

function M.moveToFolderInCwd() folderSelection("move-file") end
function M.createNewFileInFolder() folderSelection("new-in-folder") end

--------------------------------------------------------------------------------

function M.chmodx()
	local icons = require("genghis.config").config.icons

	local filepath = vim.api.nvim_buf_get_name(0)
	local perm = vim.fn.getfperm(filepath)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	vim.fn.setfperm(filepath, perm)

	local notify = require("genghis.support.notify")
	notify("Permission +x granted.", "info", { icon = icons.chmodx })
	vim.cmd.edit() -- reload the file
end

function M.trashFile()
	vim.cmd("silent! update")
	local filepath = vim.api.nvim_buf_get_name(0)
	local filename = vim.fs.basename(filepath)
	local icon = require("genghis.config").config.icons.trash
	local trashCmd = require("genghis.config").config.fileOperations.trashCmd

	-- execute the trash command
	local cmd = trashCmd()
	if type(cmd) ~= "table" then cmd = { cmd } end
	table.insert(cmd, filepath)
	local out = vim.system(cmd):wait()

	-- handle the result
	local notify = require("genghis.support.notify")
	if out.code == 0 then
		vim.api.nvim_buf_delete(0, { force = true })
		notify(("%q moved to trash."):format(filename), "info", { icon = icon })
	else
		local outmsg = (out.stdout or "") .. (out.stderr or "")
		notify(("Trashing %q failed: %s"):format(filename, outmsg), "error")
	end
end

function M.showInSystemExplorer()
	local notify = require("genghis.support.notify")
	if jit.os ~= "OSX" then
		notify("Currently only available on macOS.", "warn")
		return
	end

	local out = vim.system({ "open", "-R", vim.api.nvim_buf_get_name(0) }):wait()
	if out.code ~= 0 then
		local icon = require("genghis.config").config.icons.file
		notify("Failed: " .. out.stderr, "error", { icon = icon })
	end
end
--------------------------------------------------------------------------------
return M
