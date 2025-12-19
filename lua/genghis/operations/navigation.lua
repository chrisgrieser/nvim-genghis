local M = {}
--------------------------------------------------------------------------------

---Cycles files in folder in alphabetical order.
---If snacks.nvim is installed, adds cycling notification.
---@param direction? "next"|"prev"
function M.fileInFolder(direction)
	local notify = require("genghis.support.notify")

	if not direction then direction = "next" end
	if direction ~= "next" and direction ~= "prev" then
		notify('Invalid direction. Only "next" and "prev" are allowed.', "warn")
		return
	end

	local config = require("genghis.config").config
	local curPath = vim.api.nvim_buf_get_name(0)
	local curFile = vim.fs.basename(curPath)
	local curFolder = vim.fs.dirname(curPath)
	local icon = direction == "next" and config.icons.nextFile or config.icons.prevFile

	-- get list of files
	local itemsInFolder = vim.fs.dir(curFolder) -- INFO `fs.dir` already returns them sorted
	local filesInFolder = vim.iter(itemsInFolder):fold({}, function(acc, name, type)
		local ext = name:match("%.(%w+)$")
		local curExt = curFile:match("%.(%w+)$")

		local ignored = (config.navigation.onlySameExtAsCurrentFile and ext ~= curExt)
			or vim.tbl_contains(config.navigation.ignoreExt, ext)
			or (config.navigation.ignoreDotfiles and vim.startswith(name, "."))
			or vim.tbl_contains(config.navigation.ignoreFilesWithName, name)

		if type == "file" and not ignored then
			table.insert(acc, name) -- select only name
		end
		return acc
	end)

	-- GUARD no files to navigate to
	if #filesInFolder == 0 then -- if currently at a hidden file and there are only hidden files in the dir
		notify("No valid files found in folder.", "warn", { icon = icon })
		return
	elseif #filesInFolder == 1 then
		notify("Already at the only valid file.", "warn", { icon = icon })
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
	if not curIdx then
		local msg = "Cannot determine next file, current file itself is excluded."
		notify(msg, "warn", { icon = icon })
		return
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
		local title = direction:sub(1, 1):upper()
			.. direction:sub(2)
			.. " file"
			.. (" (%d/%d)"):format(nextIdx, #filesInFolder)
		vim.notify(msg, nil, {
			title = title,
			icon = icon,
			history = false,
			id = "next-in-folder", -- replace notifications when quickly cycling
			ft = "markdown", -- so `h1` is highlighted
		})
	end
end

--------------------------------------------------------------------------------
return M
