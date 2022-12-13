local M = {}

local logError = vim.log.levels.ERROR
local expand = vim.fn.expand
local fn = vim.fn
local cmd = vim.cmd

local function leaveVisualMode()
	-- https://github.com/neovim/neovim/issues/17735#issuecomment-1068525617
	local escKey = vim.api.nvim_replace_termcodes("<Esc>", false, true, true)
	vim.api.nvim_feedkeys(escKey, "nx", false)
end

--------------------------------------------------------------------------------

---Performing common file operation tasks
---@param op string rename|duplicate|new|newFromSel
local function fileOp(op)
	local dir = expand("%:p:h")
	local oldName = expand("%:t")
	local oldNameNoExt = oldName:gsub("%.%w+$", "")
	local oldExt = expand("%:e")
	if oldExt ~= "" then oldExt = "." .. oldExt end
	local prevReg

	if op == "newFromSel" then
		prevReg = fn.getreg("z")
		leaveVisualMode()
		cmd [['<,'>delete z]]
	end

	local promptStr, prefill
	if op == "duplicate" then
		promptStr = "Duplicate File as: "
		prefill = oldNameNoExt.. "-1"
	elseif op == "rename" then
		promptStr = "Rename File to: "
		prefill = oldNameNoExt
	elseif op == "new" or op == "newFromSel" then
		promptStr = "Name for New File: "
		prefill = ""
	end

	vim.ui.input({prompt = promptStr, default = prefill, complete = "file" }, function(newName)
		local invalidName = false
		local sameName
		if newName then
			invalidName = newName:find("^%s*$") or newName:find("[/\\:]")
			sameName = newName == oldName
		end
		if not (newName) or invalidName or sameName then -- cancel
			if op == "newFromSel" then
				cmd.undo() -- undo deletion
				fn.setreg("z", prevReg) -- restore register content
			end
			if invalidName then
				vim.notify("Invalid filename.", logError)
			elseif sameName then
				vim.notify("Cannot use the same filename.", logError)
			end
			return
		end

		local extProvided = newName:find(".%.") -- non-leading dot to not include dotfiles without extension
		if not (extProvided) then newName = newName .. oldExt end
		local filepath = dir .. "/" .. newName

		cmd.update() -- save current file; needed for users with `vim.opt.hidden=false`
		if op == "duplicate" then
			cmd.saveas(filepath)
			cmd.edit(filepath)
			vim.notify('Duplicated "' .. oldName .. '" as "' .. newName .. '".')
		elseif op == "rename" then
			local success, errormsg = os.rename(oldName, newName)
			if success then
				cmd.edit(filepath)
				cmd.bwipeout("#")
				vim.notify('Renamed "' .. oldName .. '" to "' .. newName .. '".')
			else
				vim.notify("Could not rename file: " .. errormsg, logError)
			end
		elseif op == "new" or op == "newFromSel" then
			cmd.edit(filepath)
			if op == "newFromSel" then
				cmd("put z") -- cmd.put("z") does not work here :/
				fn.setreg("z", prevReg) -- restore register content
			end
			cmd.write(filepath)
		end
	end)
end

---Rename Current File
function M.renameFile()
	fileOp("rename")
end

---Duplicate Current File
function M.duplicateFile()
	fileOp("duplicate")
end

---Create New File
function M.createNewFile()
	fileOp("new")
end

---Move Selection to New File
function M.moveSelectionToNewFile()
	fileOp("newFromSel")
end

--------------------------------------------------------------------------------

---copying file information
---@param operation string filename|filepath
local function copyOp(operation)
	local reg = '"'
	local clipboardOpt = vim.opt.clipboard:get();
	local useSystemClipb = #clipboardOpt > 0 and clipboardOpt[1]:find("unnamed")
	if useSystemClipb then reg = "+" end

	local toCopy = expand("%:p")
	if operation == "filename" then toCopy = expand("%:t") end

	fn.setreg(reg, toCopy)
	vim.notify("COPIED\n" .. toCopy)
end

---Copy absolute path of current file
function M.copyFilepath()
	copyOp("filepath")
end

---Copy name of current file
function M.copyFilename()
	copyOp("filename")
end

--------------------------------------------------------------------------------

---Makes current file executable
function M.chmodx()
	local filename = expand("%")
	local perm = fn.getfperm(filename)
	perm = perm:gsub("r(.)%-", "r%1x") -- add x to every group that has r
	fn.setfperm(filename, perm)
	vim.notify("Execution Permission granted.")
end

---Trash the current File.
---@param opts? table
function M.trashFile(opts)
	cmd.update{bang = true}
	local trash = os.getenv("HOME") .. "/.Trash/"
	if opts and opts.trashLocation then
		trash = opts.trashLocation
		if not (trash:find("/$")) then
			trash = trash .. "/"
		end
	end

	local currentFile = expand("%:p")
	local filename = expand("%:t")
	local success, errormsg = os.rename(currentFile, trash .. filename)

	if success then
		cmd.bwipeout()
		vim.notify('"' .. filename .. '" deleted.')
	else
		vim.notify("Could not delete file: " .. errormsg, logError)
	end
end

return M
