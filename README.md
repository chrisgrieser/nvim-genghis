# nvim-genghis ⚔️
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis"><img src="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis" /></a>

Convenience file operations for neovim, written in lua. 

<!--toc:start-->
- [How is this different from `vim.eunuch`?](#how-is-this-different-from-vimeunuch)
- [Installation and Setup](#installation-and-setup)
- [Available Commands](#available-commands)
	- [File Operation Command](#file-operation-command)
	- [File Utility Commands](#file-utility-commands)
	- [Disable Ex-Commands](#disable-ex-commands)
- [Autocompletion of directories](#autocompletion-of-directories)
- [Why that name](#why-that-name)
- [About me](#about-me)
<!--toc:end-->

## How is this different from `vim.eunuch`?
- Various improvements like automatically keeping the extensions when no extension is given, or moving files to the trash instead of removing them.
- Uses only vim-commands or lua os-modules, so it has no dependencies and works cross-platform.
- Makes use of up-to-date nvim features like `vim.ui.input` or `vim.notify`. This means you can get nicer input fields with normal mode support via plugins like [dressing.nvim](https://github.com/stevearc/dressing.nvim), and confirmation notices with plugins like [nvim-notify](https://github.com/rcarriga/nvim-notify), if they are installed and setup.
- If used with dressing and cmp, [you can also get autocompletion of directories](#autocompletion-of-directories).
- Written 100% in lua. 

## Installation and Setup

```lua
-- Packer
use {"chrisgrieser/nvim-genghis", requires = "stevearc/dressing.nvim"}

-- Lazy
{"chrisgrieser/nvim-genghis", dependencies = "stevearc/dressing.nvim"},
```

`nvim-genghis` (and `dressing.nvim`) require no `.setup()` function. Just create keybindings for the commands you want to use:

```lua
local keymap = vim.keymap.set
local genghis = require("genghis")
keymap("n", "<leader>yp", genghis.copyFilepath)
keymap("n", "<leader>yn", genghis.copyFilename)
keymap("n", "<leader>cx", genghis.chmodx)
keymap("n", "<leader>rf", genghis.renameFile)
keymap("n", "<leader>mf", genghis.moveAndRenameFile)
keymap("n", "<leader>nf", genghis.createNewFile)
keymap("n", "<leader>yf", genghis.duplicateFile)
keymap("n", "<leader>df", function () genghis.trashFile{trashLocation = "your/path"} end) -- default: "$HOME/.Trash".
keymap("x", "<leader>x", genghis.moveSelectionToNewFile)
```

## Available Commands

### File Operation Command
- `.createNewFile` or `:New`: Create a new file.
- `.duplicateFile` or `:Duplicate`: Duplicate the current file.
- `.moveSelectionToNewFile` or `:NewFromSelection`: Prompts for a new file name and moves the current selection to that new file. (Note that this is a Visual Line Mode command; the selection is moved linewise.)
- `.renameFile` or `:Rename`: Rename the current file.
- `.moveAndRenameFile` or `:Move`: Move and Rename the current file. Works like the UNIX `mv` command. Best used with [autocompletion of directories](#autocompletion-of-directories).

The following applies to all commands above: 
- If no extension has been provided, uses the extension of the original file.
- If the new file name includes a `/`, the new file is placed in the respective subdirectory, creating any non-existing folders. Except for `.moveAndRenameFile`, all operations take only place in the current working directory, so `.moveAndRenameFile` is the only command that can move to a parent directory.
- All commands support [autocompletion of existing directories](#autocompletion-of-directories).

### File Utility Commands
- `.trashFile{trashLocation = "/your/path/"}` or `:Trash`: Move the current file to the trash location. [Defaults to the operating-system-specific trash directory.](https://github.com/chrisgrieser/nvim-genghis/blob/main/lua/genghis.lua#L164) ⚠️ Any existing file in the trash location with the same name is overwritten, making that file irretrievable. If [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim) is available, `require'bufdelete.nvim'.bufwipeout` would be used to keep window layout intact instead of `vim.cmd.bwipeout`.
- `.copyFilename` or `:CopyFilename`: Copy the file name. When `clipboard="unnamed[plus]"` has been set, copies to the `+` register, otherwise to `"`.
- `.copyFilepath` or `:CopyFilepath`: Copy the absolute file path. When `clipboard="unnamed[plus]"` has been set, copies to the `+` register, otherwise to `"`.
- `.chmodx` or `:Chmodx`: Makes current file executable. Equivalent to `chmod +x`.

### Disable Ex-Commands
Put this in your configuration file:

```lua
-- lua
vim.g.genghis_disable_commands = true
```

```vim
-- viml
let g:genghis_disable_commands = v:true
```

## Autocompletion of directories
You can get autocompletion for directories by using `dressing.nvim`, `nvim-cmp`, and vim's omnifunc:

```lua
-- packer
use { "chrisgrieser/nvim-genghis", requires = {
		"stevearc/dressing.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-omni",
	},
}
-- lazy
{ "chrisgrieser/nvim-genghis", dependencies = {
		"stevearc/dressing.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-omni",
	},
},
```

```lua
-- required setup for cmp, somewhere after your main cmp-config
require("cmp").setup.filetype("DressingInput", {
	sources = cmp.config.sources { {name = "omni"} },
})
```

## Why that name
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch) - as opposed to childless eunuchs, it is said that Genghis Khan [has fathered thousands of children](https://allthatsinteresting.com/genghis-khan-children).

<!-- vale Google.FirstPerson = NO -->
## About me
In my day job, I am a sociologist studying the social mechanisms underlying the digital economy. For my PhD project, I investigate the governance of the app economy and how software ecosystems manage the tension between innovation and compatibility. If you are interested in this subject, feel free to get in touch.

__Blog__  
I also occassionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

__Profiles__
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [GitHub](https://github.com/chrisgrieser/)
- [Twitter](https://twitter.com/pseudo_meta)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

__Buy Me a Coffee__  
<br>
<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
