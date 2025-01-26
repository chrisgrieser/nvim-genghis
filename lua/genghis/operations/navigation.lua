local M = {}
local u = require("genghis.support.utils")
--------------------------------------------------------------------------------

---Cycles files in folder in alphabetical order.
---If snacks.nvim is installed, adds cycling notification.
---@param direction? "next"|"prev"
function M.fileInFolder(direction)
	if not direction then direction = "next" end
	if direction ~= "next" and direction ~= "prev" then
		u.notify('Invalid direction. Only "next" and "prev" are allowed.', "warn")
		return
	end

	local ignoreExt = require("genghis.config").config.navigation.ignoreExt
	local icons = require("genghis.config").config.icons

	local curPath = vim.api.nvim_buf_get_name(0)
	local curFile = vim.fs.basename(curPath)
	local curFolder = vim.fs.dirname(curPath)

	local notifyOpts = {
		title = direction:sub(1, 1):upper() .. direction:sub(2) .. " file",
		icon = direction == "next" and icons.nextFile or "󰖿",
		id = "next-in-folder", -- replace notifications when quickly cycling
		ft = "markdown", -- so `h1` is highlighted
	}

	-- get list of files
	local itemsInFolder = vim.fs.dir(curFolder) -- INFO `fs.dir` already returns them sorted
	local filesInFolder = vim.iter(itemsInFolder):fold({}, function(acc, name, type)
		local ext = name:match("%.(%w+)$")
		if type ~= "file" or name:find("^%.") or vim.tbl_contains(ignoreExt, ext) then return acc end
		table.insert(acc, name) -- select only name
		return acc
	end)

	-- GUARD if currently at a hidden file and there are only hidden files in the dir
	if #filesInFolder == 0 then
		vim.notify("No valid files found in folder.", vim.log.levels.ERROR, notifyOpts)
		return
	end

	-- determine next index
	local curIdx
	for idx = 1, #filesInFolder do
		if filesInFolder[idx] == curFile then
			curIdx = idx
			break
		end
	end
	local nextIdx = curIdx + (direction == "next" and 1 or -1)
	if nextIdx < 1 then nextIdx = #filesInFolder end
	if nextIdx > #filesInFolder then nextIdx = 1 end

	-- goto file
	local nextFile = curFolder .. "/" .. filesInFolder[nextIdx]
	vim.cmd.edit(nextFile)

	-- notification
	if package.loaded["snacks"] then
		local msg = vim
			.iter(filesInFolder)
			:map(function(file)
				-- mark current, using markdown h1
				local prefix = file == filesInFolder[nextIdx] and "#" or "-"
				return prefix .. " " .. file
			end)
			:slice(nextIdx - 5, nextIdx + 5) -- display ~5 files before/after
			:join("\n")
		notifyOpts.title = notifyOpts.title .. (" (%d/%d)"):format(nextIdx, #filesInFolder)
		vim.notify(msg, nil, notifyOpts)
	end
end

--------------------------------------------------------------------------------
return M
