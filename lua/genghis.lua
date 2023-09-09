local M = {}

local expand = vim.fn.expand
local fn = vim.fn
local cmd = vim.cmd

local function bwipeout(bufnr)
	bufnr = bufnr and fn.bufnr(bufnr) or 0
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function leaveVisualMode()
	-- https://github.com/neovim/neovim/issues/17735#issuecomment-1068525617
	local escKey = vim.api.nvim_replace_termcodes("<Esc>", false, true, true)
	vim.api.nvim_feedkeys(escKey, "nx", false)
end


---send notification
---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
local function notify(msg, level)
	if not level then level = "info" end
	vim.notify(msg, vim.log.levels[level:upper()], { title = "nvim-genghis" })
end

--------------------------------------------------------------------------------

local function fileExists(filepath)
	return vim.loop.fs_stat(filepath) ~= nil
end

---Performing common file operation tasks
---@param op string rename|duplicate|new|newFromSel
local function fileOp(op)
	local dir = fn.getcwd()
	local oldName = expand("%:t")
	local oldFilePath = expand("%:p")
	local oldNameNoExt = oldName:gsub("%.%w+$", "")
	local oldExt = expand("%:e")
	if oldExt ~= "" then oldExt = "." .. oldExt end

	local prevReg
	if op == "newFromSel" then
		prevReg = fn.getreg("z")
		leaveVisualMode()
		cmd([['<,'>delete z]])
	end

	local promptStr, prefill
	if op == "duplicate" then
		promptStr = "Duplicate File as: "
		prefill = oldNameNoExt .. "-1"
	elseif op == "rename" then
		promptStr = "Rename File to: "
		prefill = oldNameNoExt
	elseif op == "move-rename" then
		promptStr = "Move & Rename File to: "
		prefill = dir .. "/"
	elseif op == "new" or op == "newFromSel" then
		promptStr = "Name for New File: "
		prefill = ""
	end

	-- selene: allow(high_cyclomatic_complexity)
	-- INFO completion = "dir" allows for completion via cmp-omni
	vim.ui.input({ prompt = promptStr, default = prefill, completion = "dir" }, function(newName)
		-- Clear message area from ui.input prompt
		cmd("echomsg ''")
		-- VALIDATION OF FILENAME
		if not newName then return end -- input has been cancelled

		local invalidName = newName:find("^%s+$")
			 or newName:find("[\\:]")
			 or newName:find("/$")
			 or (newName:find("^/") and not op == "move-rename")
		local sameName = newName == oldName
		local emptyInput = newName == ""

		if invalidName or sameName or (emptyInput and op ~= "new") then
			if op == "newFromSel" then
				cmd.undo()      -- undo deletion
				fn.setreg("z", prevReg) -- restore register content
			end
			if invalidName or emptyInput then
				notify("Invalid filename.", "error")
			elseif sameName then
				notify("Cannot use the same filename.", "error")
			end
			return
		end

		-- exception: new file creaton allows for empty input
		if emptyInput and op == "new" then newName = "Untitled" end

		-- DETERMINE PATH AND EXTENSION
		local hasPath = newName:find("/")
		if hasPath then
 			local newFolder = vim.fs.dirname(newName)
			fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local extProvided = newName:find(".%.[^/]*$") -- non-leading dot to not include dotfiles without extension
		if not extProvided then newName = newName .. oldExt end
		local newFilePath = (op == "move-rename") and newName or dir .. "/" .. newName

		if fileExists(newFilePath) then
			notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		cmd.update() -- save current file; needed for users with `hidden=false`
		if op == "duplicate" then
			if vim.loop.fs_copyfile(oldFilePath, newFilePath) then
				cmd.edit(newFilePath)
				notify(("Duplicated %q as %q."):format(oldName, newName))
			end
		elseif op == "rename" or op == "move-rename" then
			if vim.loop.fs_rename(oldFilePath, newFilePath) then
				cmd.edit(newFilePath)
				bwipeout("#")
				notify(("Renamed %q as %q."):format(oldName, newName))
			end
		elseif op == "new" or op == "newFromSel" then
			cmd.edit(newFilePath)
			if op == "newFromSel" then
				cmd("put z")    -- cmd.put("z") does not work here :/
				fn.setreg("z", prevReg) -- restore register content
			end
			cmd.write(newFilePath)
		end
	end)
end

---Rename Current File
function M.renameFile() fileOp("rename") end

---Move and Rename Current File
function M.moveAndRenameFile() fileOp("move-rename") end

---Duplicate Current File
function M.duplicateFile() fileOp("duplicate") end

---Create New File
function M.createNewFile() fileOp("new") end

---Move Selection to New File
function M.moveSelectionToNewFile() fileOp("newFromSel") end

--------------------------------------------------------------------------------

---copying file information
---@param operation string filename|filepath
local function copyOp(expandOperation)
	local reg = '"'
	local clipboardOpt = vim.opt.clipboard:get()
	local useSystemClipb = vim.g.genghis_use_systemclipboard or (#clipboardOpt > 0 and clipboardOpt[1]:find("unnamed"))
	if useSystemClipb then reg = "+" end

	local toCopy = expand(expandOperation)
	fn.setreg(reg, toCopy)
	vim.notify(toCopy, vim.log.levels.INFO, { title = "Copied" })
end

---Copy absolute path of current file
function M.copyFilepath() copyOp("%:p") end

---Copy name of current file
function M.copyFilename() copyOp("%:t") end

---Copy relative path of current file
function M.copyRelativePath() copyOp("%:~:.") end

---Copy absolute directory path of current file
function M.copyDirectoryPath() copyOp("%:p:h") end

---Copy relative directory path of current file
function M.copyRelativeDirectoryPath() copyOp("%:~:.:h") end

--------------------------------------------------------------------------------

---Makes current file executable
function M.chmodx()
	local filename = expand("%")
	local perm = fn.getfperm(filename)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	fn.setfperm(filename, perm)
	notify("Execution Permission granted.")
	cmd.edit()
end

---Trash the current File.
---@param opts? table
function M.trashFile(opts)
	cmd.update { bang = true }
	local trash
	local home = os.getenv("HOME")
	local oldName = expand("%:t")
	local oldFilePath = expand("%:p")

	-- Default trash locations
	if fn.has("linux") == 1 then
		local xdg_data = os.getenv("XDG_DATA_HOME")
		trash = xdg_data and xdg_data .. "/Trash/" or home .. "/.local/share/Trash/"
	elseif fn.has("macunix") == 1 then
		-- INFO macOS moves files to the icloud trash, if they are deleted from
		-- icloud folder, otherwise they go the user trash folder
		local iCloudPath = home .. "/Library/Mobile Documents/com~apple~CloudDocs"
		local isInICloud = fn.expand("%:p:h"):sub(1, #iCloudPath) == iCloudPath
		trash = isInICloud and iCloudPath .. "/.Trash/" or home .. "/.Trash/"
	else
		-- TODO: support windows
		trash = home .. "/.Trash/"
	end

	-- overwrite trash location, if specified by user
	if opts and opts.trashLocation then
		trash = opts.trashLocation
		if not (trash:find("/$")) then trash = trash .. "/" end -- append "/"
	end

	fn.mkdir(trash, "p")

	if fileExists(trash .. oldName) then
		oldName = oldName .. "~"
	end

	if vim.loop.fs_rename(oldFilePath, trash .. oldName) then
		bwipeout()
		notify(("%q deleted"):format(oldName))
	end
end

return M
