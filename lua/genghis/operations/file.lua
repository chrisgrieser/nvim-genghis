local M = {}

local backdrop = require("genghis.support.backdrop")
local rename = require("genghis.support.lsp-rename")
local u = require("genghis.support.utils")
local osPathSep = package.config:sub(1, 1)
--------------------------------------------------------------------------------

---@param op "rename"|"duplicate"|"new"|"new-from-selection"|"move-rename"
local function fileOp(op)
	local oldFilePath = vim.api.nvim_buf_get_name(0)
	local oldName = vim.fs.basename(oldFilePath)
	local dir = vim.fs.dirname(oldFilePath) -- same directory, *not* pwd
	local oldNameNoExt = oldName:gsub("%.%w+$", "")
	local oldExt = vim.fn.expand("%:e")
	if oldExt ~= "" then oldExt = "." .. oldExt end
	local lspSupportsRenaming = rename.lspSupportsRenaming()

	local prevReg
	if op == "new-from-selection" then
		prevReg = vim.fn.getreg("z")
		u.leaveVisualMode()
		vim.cmd([['<,'>delete z]])
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
	elseif op == "new" or op == "new-from-selection" then
		promptStr = "Name for New File: "
		prefill = ""
	end

	-- backdrop
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("InputGenghisBackdrop", {}),
		pattern = "DressingInput",
		callback = function(ctx) backdrop.new(ctx.buf) end,
	})

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
		local hasPath = newName:find(osPathSep)
		if hasPath then
			local newFolder = vim.fs.dirname(newName)
			vim.fn.mkdir(newFolder, "p") -- create folders if necessary
		end

		local extProvided = newName:find(".%.[^/]*$") -- non-leading dot to not include dotfiles without extension
		if not extProvided then newName = newName .. oldExt end
		local newFilePath = (op == "move-rename") and newName or dir .. osPathSep .. newName

		if u.fileExists(newFilePath) then
			u.notify(("File with name %q already exists."):format(newFilePath), "error")
			return
		end

		-- EXECUTE FILE OPERATION
		vim.cmd.update()
		if op == "duplicate" then
			local success = vim.uv.fs_copyfile(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				u.notify(("Duplicated %q as %q."):format(oldName, newName))
			end
		elseif op == "rename" or op == "move-rename" then
			rename.sendWillRenameToLsp(oldFilePath, newFilePath)
			local success = rename.moveFile(oldFilePath, newFilePath)
			if success then
				vim.cmd.edit(newFilePath)
				u.bwipeout("#")
				u.notify(("Renamed %q to %q."):format(oldName, newName))
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
	local parentOfCurFile = vim.fs.dirname(curFilePath) .. osPathSep
	local filename = vim.fs.basename(curFilePath)
	local lspSupportsRenaming = rename.lspSupportsRenaming()
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

	local autocmd = vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("SelectorGenghisBackdrop", {}),
		pattern = { "DressingSelect", "TelescopePrompt" },
		callback = function(ctx) backdrop.new(ctx.buf) end,
	})

	-- prompt user and move
	local promptStr = "Choose Destination Folder"
	if lspSupportsRenaming then promptStr = promptStr .. " (with updated imports)" end
	vim.ui.select(foldersInCwd, {
		prompt = promptStr,
		kind = "genghis.moveToFolderInCwd",
		format_item = function(path) return path:sub(#cwd) end, -- only relative path
	}, function(destination)
		-- in case neither dressing nor telescope was used as selector-backend
		vim.api.nvim_del_autocmd(autocmd)

		if not destination then return end
		local newFilePath = destination .. osPathSep .. filename

		-- GUARD
		if u.fileExists(newFilePath) then
			u.notify(("File %q already exists at %q."):format(filename, destination), "error")
			return
		end

		rename.sendWillRenameToLsp(curFilePath, newFilePath)
		local success = rename.moveFile(curFilePath, newFilePath)
		if success then
			vim.cmd.edit(newFilePath)
			u.bwipeout("#")
			local msg = ("Moved %q to %q"):format(filename, destination)
			local append = lspSupportsRenaming and " and updated imports." or "."
			u.notify(msg .. append)
			if lspSupportsRenaming then vim.cmd.wall() end
		end
	end)
end

--------------------------------------------------------------------------------
return M
