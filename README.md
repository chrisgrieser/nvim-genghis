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
- [Available commands](#available-commands)
  * [File operations](#file-operations)
  * [Path copying](#path-copying)
  * [Other operations](#other-operations)
- [Why that name?](#why-that-name)
- [About the author](#about-the-author)

<!-- tocstop -->

## Features
- Commands for moving, renaming, creating, deleting, or duplicating files and
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
{ 
	"chrisgrieser/nvim-genghis", 
	dependencies = "stevearc/dressing.nvim"
	cmd = "Genghis",
	opts = {}, -- empty table needed even for default config due to lazy.nvim bug, see #51
},

-- packer
use { 
	"chrisgrieser/nvim-genghis", 
	requires = "stevearc/dressing.nvim"
}
```

## Configuration
The `setup` call is optional.

```lua
-- default config
require("genghis").setup {
	backdrop = {
		enabled = true,
		blend = 50,
	},
	-- default is `"trash"` on Mac/Windows, and `{ "gio", "trash" }` on Linux
	trashCmd = "trash",
}
```

## Usage
You can access a command via the lua API:

```lua
require("genghis").createNewFile()
```

Or you can use the ex command `:Genghis` with the respective sub-command:

```txt
:Genghis createNewFile
```

> [!TIP]
> Previously, the plugins used ex commands such as `:New` or `:Move`. To avoid
> conflicts, the ex commands are now only available as sub-commands of
> `:Genghis`. If you prefer the old, shorter ex commands, you can use
> abbreviations to re-create them, for example: `vim.cmd.cabbrev("New Genghis
> createNewFile")`.

## Available commands

### File operations
- `.createNewFile`: Create a new file.
- `.duplicateFile`: Duplicate the current file.
- `.moveSelectionToNewFile`: Prompts for a new file name
  and moves the current selection to that new file. (Note that this is a Visual
  Line mode command, the selection is moved linewise.)
- `.renameFile`: Rename the current file.
- `.moveAndRenameFile`: Move and Rename the current file. Keeps the
  old name if the new path ends with `/`. Works like the Unix `mv` command.
- `.moveToFolderInCwd`: Move the current file to an existing folder in the
  current working directory.

The following applies to all commands above:
1. If no extension has been provided, uses the extension of the original file.
2. If the new file name includes a `/`, the new file is placed in the
   respective subdirectory, creating any non-existing folders.
3. All movement and renaming commands update `import` statements to the renamed
   file (if the LSP supports `workspace/willRenameFiles`).

### Path copying
- `.copyFilename`: Copy the file name.
- `.copyFilepath`: Copy the absolute file path.
- `.copyFilepathWithTilde`: Copy the absolute file path, replacing the home
  directory with `~`.
- `.copyRelativePath`: Copy the relative file path.
- `.copyDirectoryPath`: Copy the absolute directory path.
- `.copyRelativeDirectoryPath`: Copy the relative directory path.

All commands use the system clipboard.

### Other operations
- `.chmodx`: Makes current file executable. Equivalent to `chmod
  +x`.
- `.trashFile`: Move the current file
to the trash location.
	* Defaults to `gio trash` on *Linux*, `trash` on *Mac* and *Windows*.
	* If [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim) is available,
	  `require'bufdelete.nvim'.bufwipeout` would be used to keep window layout
	  intact instead of `vim.cmd.bwipeout`.

> [!NOTE]
> The trash CLIs are usually not available by default, and must be installed.

## Why that name?
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch), an older vimscript
plugin with a similar goal. As opposed to childless eunuchs, it is said that
Genghis Khan [has fathered thousands of
children](https://allthatsinteresting.com/genghis-khan-children).

<!-- vale Google.FirstPerson = NO -->
## About the author
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

- [Academic Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
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
