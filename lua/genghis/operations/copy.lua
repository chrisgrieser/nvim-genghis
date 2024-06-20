local M = {}
--------------------------------------------------------------------------------

---@param expandOperation string
local function copyOp(expandOperation)
	local register = "+"
	local toCopy = vim.fn.expand(expandOperation)
	vim.fn.setreg(register, toCopy)
	vim.notify(toCopy, vim.log.levels.INFO, { title = "Copied" })
end

-- DOCS for the modifiers
-- https://neovim.io/doc/user/builtin.html#expand()
-- https://neovim.io/doc/user/cmdline.html#filename-modifiers
function M.copyFilepath() copyOp("%:p") end
function M.copyFilepathWithTilde() copyOp("%:~") end
function M.copyFilename() copyOp("%:t") end
function M.copyRelativePath() copyOp("%:.") end
function M.copyDirectoryPath() copyOp("%:p:h") end
function M.copyRelativeDirectoryPath() copyOp("%:.:h") end

--------------------------------------------------------------------------------
return M
