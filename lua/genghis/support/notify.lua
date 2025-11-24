---@param msg string
---@param level? "info"|"warn"|"error"
---@param opts? table
return function(msg, level, opts)
	local successNotify = require("genghis.config").config.successNotifications
	if not level then level = "info" end
	if level == "info" and not successNotify then return end
	if not opts then opts = {} end

	opts.title = opts.title and "Genghis: " .. opts.title or "Genghis"
	opts.ft = "text" -- prevent `~` from creating strikethroughs in `snacks.notifier`
	vim.notify(msg, vim.log.levels[level:upper()], opts)
end
