<!-- LTeX: enabled=false -->
# nvim-genghis ⚔️
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis/shield"/></a>

Lightweight and quick file operations without being a full-blown file manager.

<!-- toc -->

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Available Commands](#available-commands)
	* [File Operations](#file-operations)
	* [Path Copying](#path-copying)
	* [Other operations](#other-operations)
	* [Disable Ex-Commands](#disable-ex-commands)
- [How is this different from `vim.eunuch`?](#how-is-this-different-from-vimeunuch)
- [Why that Name](#why-that-name)
- [About the Author](#about-the-author)

<!-- tocstop -->

## Features
- Commands for moving, renaming, creating, deleting, or, duplicating files and
  more.
- Commands for copying the path or name of the current file in various formats.
- All movement and renaming commands update `import` statements to the renamed
  file (if the LSP supports `workspace/willRenameFiles`).
- Lightweight: no file management UI or file tree.
- Various quality-of-life improvements like automatically keeping the extensions
  when no extension is given, or the ability to use vim motions in the input
  field.

## Installation

```lua
-- lazy.nvim
{"chrisgrieser/nvim-genghis", dependencies = "stevearc/dressing.nvim"},

-- packer
use {"chrisgrieser/nvim-genghis", requires = "stevearc/dressing.nvim"}
```

## Configuration
The `setup` call is optional.

```lua
-- default config
require("genghis").setup {
	-- cli name, default is `trash` on Mac and Windows, and `gio trash` on Linux
	trashCmd = "trash",
}
```

## Usage

```lua
local keymap = vim.keymap.set
keymap("n", "<leader>yp", function() require("genghis").copyFilepath() end)
keymap("n", "<leader>yn", function() require("genghis").copyFilename() end)
keymap("n", "<leader>cx", function() require("genghis").chmodx() end)
keymap("n", "<leader>rf", function() require("genghis").renameFile() end)
keymap("n", "<leader>mf", function() require("genghis").moveAndRenameFile() end)
keymap("n", "<leader>mc", function() require("genghis").moveToFolderInCwd() end)
keymap("n", "<leader>nf", function() require("genghis").createNewFile() end)
keymap("n", "<leader>yf", function() require("genghis").duplicateFile() end)
keymap("n", "<leader>df", function() require("genghis").trashFile() end)
keymap("x", "<leader>x", function() require("genghis").moveSelectionToNewFile() end)
```

## Available Commands

### File Operations
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

### Path Copying
- `.copyFilename` or `:CopyFilename`: Copy the file name.
- `.copyFilepath` or `:CopyFilepath`: Copy the absolute file path.
- `.copyFilepathWithTilde` or `:CopyFilepathWithTilde`: Copy the absolute file
  path, replacing the home directory with `~`.
- `.copyRelativePath` or `:CopyRelativePath`: Copy the relative file path.
- `.copyDirectoryPath` or `:CopyDirectoryPath`: Copy the absolute directory
  path.
- `.copyRelativeDirectoryPath` or `:CopyRelativeDirectoryPath`: Copy the
  relative directory path.

All commands use the system clipboard.

### Other operations
- `.chmodx` or `:Chmodx`: Makes current file executable. Equivalent to `chmod
  +x`.
- `.trashFile` or `:Trash`: Move the current file
to the trash location.
	* Defaults to `gio trash` on *Linux*, `trash` on *Mac* and *Windows*.
	* If [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim) is available,
	  `require'bufdelete.nvim'.bufwipeout` would be used to keep window layout
	  intact instead of `vim.cmd.bwipeout`.

> [!NOTE]
> The trash CLIs are usually not available by default, and must be installed.

### Disable Ex-Commands

```lua
vim.g.genghis_disable_commands = true
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

## Why that Name
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch). As opposed to
childless eunuchs, it is said that Genghis Khan [has fathered thousands of
children](https://allthatsinteresting.com/genghis-khan-children).

<!-- vale Google.FirstPerson = NO -->
## About the Author
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

- [Academic Website](https://chris-grieser.de/)
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
