<!-- LTeX: enabled=false -->
# nvim-genghis ⚔️
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis/shield"/></a>

Lightweight and quick file operations without being a full-blown file manager.

<img alt="Showcase for renaming files" width=50% src="https://github.com/user-attachments/assets/010f3786-e4b2-4c4e-8cbb-a7618de93eb7">

## Table of contents

<!-- toc -->

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Available commands](#available-commands)
	* [File operations](#file-operations)
	* [Copy operations](#copy-operations)
	* [Other operations](#other-operations)
- [Why that name?](#why-that-name)
- [About the author](#about-the-author)

<!-- tocstop -->

## Features
- Perform **common file operations**: moving, renaming, creating, deleting, or
  duplicating files.
- **Copy** the path or name of the current file in various formats.
- All movement and renaming commands **update `import` statements** to the
  renamed file (if the LSP supports `workspace/willRenameFiles`).
- **Quality of life**: automatically keep the extension when no extension is
  given, use vim motions in the input field, confirmatory notifications, and
  more.
- **Lightweight**: no file management UI or file tree.

## Installation
An `vim.ui.input` provider is not strictly needed, but recommended for the nicer
input UI. [dressing.nvim](http://github.com/stevearc/dressing.nvim) and
[snacks.nvim](http://github.com/folke/snacks.nvim) are such providers.

```lua
-- lazy.nvim
{ 
	"chrisgrieser/nvim-genghis",
	cmd = "Genghis",
	opts = {}, -- empty table needed even for default config
},

-- packer
use { 
	"chrisgrieser/nvim-genghis", 
}
```

## Configuration
The `setup` call is required for `lazy.nvim`, but otherwise optional.

```lua
-- default config
require("genghis").setup {
	-- default is `"trash"` on Mac/Windows, and `{ "gio", "trash" }` on Linux
	trashCmd = "trash",

	-- set to empty string to disable
	-- (some icons are only used for notification plugins like `snacks.nvim`)
	icons = {
		chmodx = "󰒃",
		copyPath = "󰅍",
		duplicate = "",
		file = "󰈔",
		move = "󰪹",
		new = "",
		rename = "󰑕",
		trash = "󰩹",
	}
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
   respective subdirectory, creating any non-existing intermediate folders.
3. All movement and renaming commands update `import` statements to the renamed
   file (if the LSP supports `workspace/willRenameFiles`).

### Copy operations
- `.copyFilename`: Copy the file name.
- `.copyFilepath`: Copy the absolute file path.
- `.copyFilepathWithTilde`: Copy the absolute file path, replacing the home
  directory with `~`.
- `.copyRelativePath`: Copy the relative file path.
- `.copyDirectoryPath`: Copy the absolute directory path.
- `.copyRelativeDirectoryPath`: Copy the relative directory path.
- `.copyFileItself`: Copies the file itself. This means you can paste it into
  the browser or file manager. (Currently only on macOS, PRs welcome.)

All commands use the system clipboard.

### Other operations
- `.chmodx`: Makes current file executable. Equivalent to `chmod
  +x`.
- `.trashFile`: Move the current file to the trash location. Defaults to `gio
  trash` on *Linux*, and `trash` on *macOS* or *Windows*.
	* If [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim) is available,
	  `require("bufdelete.nvim").bufwipeout` is used to keep window layout intact
	  instead of `vim.cmd.bwipeout`.

> [!NOTE]
> The trash CLIs are usually not available by default, and must be installed.

## Why that name?
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch), an older vimscript
plugin with a similar goal. As opposed to childless eunuchs, it is said that
Genghis Khan [has fathered thousands of
children](https://allthatsinteresting.com/genghis-khan-children).

## About the author
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

- [Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'> <img height='36'
style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
