local command = vim.api.nvim_create_user_command
local genghis = require("genghis")

command("NewFromSelection", function() genghis.moveSelectionToNewFile() end, {})
command("Duplicate", function() genghis.duplicateFile() end, {})
command("Rename", function() genghis.renameFile() end, {})
command("Trash", function() genghis.trashFile() end, {})
command("Move", function() genghis.moveAndRenameFile() end, {})
command("CopyFilename", function() genghis.copyFilename() end, {})
command("CopyFilepath", function() genghis.copyFilepath() end, {})
command("Chmodx", function() genghis.chmodx() end, {})
command("New", function() genghis.createNewFile() end, {})
