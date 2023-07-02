if vim.g.genghis_disable_commands then
	vim.g.genghis_disable_commands = false
end

if not vim.g.genghis_disable_commands then
	local command = vim.api.nvim_create_user_command
	local genghis = require("genghis")
	command("NewFromSelection", function() genghis.moveSelectionToNewFile() end, { range = true })
	command("Duplicate", function() genghis.duplicateFile() end, {})
	command("Rename", function() genghis.renameFile() end, {})
	command("Trash", function() genghis.trashFile() end, {})
	command("Move", function() genghis.moveAndRenameFile() end, {})
	command("CopyFilename", function() genghis.copyFilename() end, {})
	command("CopyFilepath", function() genghis.copyFilepath() end, {})
	command("Chmodx", function() genghis.chmodx() end, {})
	command("New", function() genghis.createNewFile() end, {})
end
