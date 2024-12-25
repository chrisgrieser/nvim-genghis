vim.api.nvim_create_user_command("Genghis", function(ctx) require("genghis")[ctx.args]() end, {
	nargs = 1,
	complete = function(query)
		local allOps = {}
		vim.list_extend(allOps, vim.tbl_keys(require("genghis.operations.file")))
		vim.list_extend(allOps, vim.tbl_keys(require("genghis.operations.copy")))
		return vim.tbl_filter(function(op) return op:lower():find(query, nil, true) end, allOps)
	end,
})
