<!-- LTeX: enabled=false -->
# nvim-genghis ⚔️
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis/shield"/></a>

Lightweight and quick file operations without being a full-blown file manager.

<!-- toc -->

- [Features](#features)
- [Installation and Setup](#installation-and-setup)
- [Available Commands](#available-commands)
	* [File Operation Commands](#file-operation-commands)
	* [Utility Commands](#utility-commands)
	* [Path Copying Commands](#path-copying-commands)
	* [Disable Ex-Commands](#disable-ex-commands)
- [Cookbook](#cookbook)
	* [Use Telescope for `.moveToFolderInCwd`](#use-telescope-for-movetofolderincwd)
	* [Autocompletion of directories for `.moveAndRenameFile`](#autocompletion-of-directories-for-moveandrenamefile)
- [How is this different from `vim.eunuch`?](#how-is-this-different-from-vimeunuch)
- [Why that name](#why-that-name)
- [About me](#about-me)

<!-- tocstop -->

## Features
- Commands for moving, renaming, creating, deleting, or, duplicating files and
  more.
- Commands for copying the path or name of the current file in various formats.
- All movement and renaming commands update `import` statements to the renamed
  file (if the LSP supports `workspace/willRenameFiles`).
- Lightweight: no file management UI or file tree.
- Various quality-of-life improvements like automatically keeping the extensions
  when no extension is given.
- Fully written in lua and makes use of up-to-date nvim features like
  `vim.ui.input`.

## Installation and Setup

```lua
-- Packer
use {"chrisgrieser/nvim-genghis", requires = "stevearc/dressing.nvim"}

-- Lazy
{"chrisgrieser/nvim-genghis", dependencies = "stevearc/dressing.nvim"},
```

`nvim-genghis` (and `dressing.nvim`) require no `.setup()` function. Just create
keybindings for the commands you want to use:

```lua
local keymap = vim.keymap.set
local genghis = require("genghis")
keymap("n", "<leader>yp", genghis.copyFilepath)
keymap("n", "<leader>yn", genghis.copyFilename)
keymap("n", "<leader>cx", genghis.chmodx)
keymap("n", "<leader>rf", genghis.renameFile)
keymap("n", "<leader>mf", genghis.moveAndRenameFile)
keymap("n", "<leader>mc", genghis.moveToFolderInCwd)
keymap("n", "<leader>nf", genghis.createNewFile)
keymap("n", "<leader>yf", genghis.duplicateFile)
keymap("n", "<leader>df", genghis.trashFile)
keymap("x", "<leader>x", genghis.moveSelectionToNewFile)
```

## Available Commands

### File Operation Commands
- `.createNewFile` or `:New`: Create a new file.
- `.duplicateFile` or `:Duplicate`: Duplicate the current file.
- `.moveSelectionToNewFile` or `:NewFromSelection`: Prompts for a new file name
  and moves the current selection to that new file. (Note that this is a Visual
  Line Mode command; the selection is moved linewise.)
- `.renameFile` or `:Rename`: Rename the current file.
- `.moveAndRenameFile` or `:Move`: Move and Rename the current file. Keeps the
  old name if the new path ends with `/`. Works like the UNIX `mv` command.
- `.moveToFolderInCwd` or `:MoveToFolderInCwd`: Move the current file to an
  existing folder in the current working directory. [Can use telescope for the
  selection of the destination.](#use-telescope-for-movetofolderincwd)

The following applies to all commands above:  
1. If no extension has been provided, uses the extension of the original file.
2. If the new file name includes a `/`, the new file is placed in the
   respective subdirectory, creating any non-existing folders.
3. All movement and renaming commands update `import` statements to the renamed
   file (if the LSP supports `workspace/willRenameFiles`).

### Utility Commands
- `.chmodx` or `:Chmodx`: Makes current file executable. Equivalent to `chmod
  +x`.
- `.trashFile{trashCmd = "your_cli"}` or `:Trash`: Move the current file
to the trash location.
	* Defaults to `gio trash` on *Linux*, `trash` on *Mac* and *Windows*.
	* If [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim) is available,
	  `require'bufdelete.nvim'.bufwipeout` would be used to keep window layout
	  intact instead of `vim.cmd.bwipeout`.

> [!NOTE]
> The trash CLIs are not available by default, and must be installed.

### Path Copying Commands
- `.copyFilename` or `:CopyFilename`: Copy the file name.
- `.copyFilepath` or `:CopyFilepath`: Copy the absolute file path.
- `.copyFilepathWithTilde` or `:CopyFilepathWithTilde`: Copy the absolute file
  path, replacing the home directory with `~`.
- `.copyRelativePath` or `:CopyRelativePath`: Copy the relative file path.
- `.copyDirectoryPath` or `:CopyDirectoryPath`: Copy the absolute directory
  path.
- `.copyRelativeDirectoryPath` or `:CopyRelativeDirectoryPath`: Copy the
  relative directory path.

When `clipboard="unnamed[plus]"` has been set, copies to the `+` register,
otherwise to `"`. To always use system clipboard, put this in your configuration
file:

```lua
vim.g.genghis_use_systemclipboard = true
```

### Disable Ex-Commands

```lua
vim.g.genghis_disable_commands = true
```

## Cookbook

### Use Telescope for `.moveToFolderInCwd`

```lua
require("dressing").setup {
	select = {
		backend = { "telescope" },
	},
}
```

### Autocompletion of directories for `.moveAndRenameFile`
You can get autocompletion for directories by `nvim-cmp` and vim's `omnifunc`:

```lua
-- packer
use { 
	"chrisgrieser/nvim-genghis", 
	requires = {
		"stevearc/dressing.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-omni",
	},
}
-- lazy
{ 
	"chrisgrieser/nvim-genghis", 
	dependencies = {
		"stevearc/dressing.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-omni",
	},
},
```

```lua
-- required setup for cmp, somewhere after your main cmp-config
require("cmp").setup.filetype("DressingInput", {
	sources = cmp.config.sources { { name = "omni" } },
})
```

## How is this different from `vim.eunuch`?
- Various improvements like automatically keeping the extensions when no
extension is given, or moving files to the trash instead of removing them.
- Uses only vim-commands or lua `os` modules, so it has no dependencies and
works cross-platform.
- Makes use of up-to-date nvim features like `vim.ui.input` or `vim.notify`.
This means you can get nicer input fields with normal mode support via plugins
like [dressing.nvim](https://github.com/stevearc/dressing.nvim), and
confirmation notices with plugins like
[nvim-notify](https://github.com/rcarriga/nvim-notify), if they are installed
and setup.
- LSP support when renaming.
- Written 100% in lua.

## Why that name
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch). As opposed to
childless eunuchs, it is said that Genghis Khan [has fathered thousands of
children](https://allthatsinteresting.com/genghis-khan-children).

<!-- vale Google.FirstPerson = NO -->
## About me
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

__Blog__  
I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

__Profiles__
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [GitHub](https://github.com/chrisgrieser/)
- [Twitter](https://twitter.com/pseudo_meta)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'>
<img
	height='36'
	style='border:0px;height:36px;'
	src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
	border='0'
	alt='Buy Me a Coffee at ko-fi.com'
/></a>
