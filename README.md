<!-- LTeX: enabled=false -->
# nvim-genghis ⚔️
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-genghis/shield"/></a>

Lightweight and quick file operations without being a full-blown file manager.
For when you prefer a fuzzy finder over a file tree, but still want some
convenient file operations inside nvim.

<img alt="Showcase for renaming files" width=50% src="https://github.com/user-attachments/assets/010f3786-e4b2-4c4e-8cbb-a7618de93eb7">

## Table of contents

<!-- toc -->

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
	* [File operations](#file-operations)
	* [Copy operations](#copy-operations)
	* [File navigation](#file-navigation)
- [Why the name "Genghis"?](#why-the-name-genghis)
- [About the author](#about-the-author)

<!-- tocstop -->

## Features
**Commands**
- Perform **common file operations**: moving, renaming, creating, deleting, or
  duplicating files.
- **Copy** the path or name of the current file in various formats.
- **Navigate** to the next or previous file in the current folder.

**Quality-of-life**
- All movement and renaming commands **update `import` statements** to the
  renamed file (if the LSP supports `workspace/willRenameFiles`).
- Automatically keep the extension when no extension is given.
- Use vim motions in the input field.

## Installation
**Requirements**
- nvim 0.10+
- A `vim.ui.input` provider such as
  [dressing.nvim](http://github.com/stevearc/dressing.nvim) or
  [snacks.nvim](http://github.com/folke/snacks.nvim) for an input UI that
  **supports vim motions** and looks much nicer.
- *For the trash command*: an OS-specific trash CLI like `trash` or `gio trash`.
  (Since macOS 14+, there is a `trash` CLI already built-in, so there is no need
  to install anything.)

```lua
-- lazy.nvim
{ "chrisgrieser/nvim-genghis" }

-- packer
use { "chrisgrieser/nvim-genghis" }
```

## Configuration
The `setup` call is required for `lazy.nvim`, but otherwise optional.

```lua
-- default config
require("genghis").setup {
	trashCmd = function() ---@type fun(): string|string[]
		if jit.os == "OSX" then return "trash" end -- builtin since macOS 14
		if jit.os == "Windows" then return "trash" end
		if jit.os == "Linux" then return { "gio", "trash" } end
		return "trash-cli"
	end,

	fileOperations = {
		-- automatically keep the extension when no file extension is given
		-- (everything after the first non-leading dot is treated as the extension)
		autoAddExt = true,
	},

	navigation = {
		onlySameExtAsCurrentFile = false,
		ignoreDotfiles = true,
		ignoreExt = { "png", "svg", "webp", "jpg", "jpeg", "gif", "pdf", "zip" },
		ignoreFilesWithName = { ".DS_Store" },
	},

	successNotifications = true,

	icons = { -- set an icon to empty string to disable it
		chmodx = "󰒃",
		copyFile = "󱉥",
		copyPath = "󰅍",
		duplicate = "",
		file = "󰈔",
		move = "󰪹",
		new = "󰝒",
		nextFile = "󰖽",
		prevFile = "󰖿",
		rename = "󰑕",
		trash = "󰩹",
	},
}
```

## Usage
You can access a command as Lua function:

```lua
require("genghis").createNewFile()
```

Or you can use the ex command `:Genghis` with the respective sub-command:

```vim
:Genghis createNewFile
```

### File operations
- `createNewFile`: Create a new file.
- `duplicateFile`: Duplicate the current file.
- `moveSelectionToNewFile`: Prompts for a new filename
  and moves the current selection to that new file. (Visual
  Line command, the selection is moved linewise.)
- `renameFile`: Rename the current file.
- `moveAndRenameFile`: Move and rename the current file. Keeps the
  old name if the new path ends with `/`. Works like the UNIX `mv` command.
- `moveToFolderInCwd`: Move the current file to an existing folder in the
  current working directory.
- `chmodx`: Makes current file executable. Equivalent to `chmod +x`.
- `trashFile`: Move the current file to the trash. Defaults to `gio trash` on
  *Linux*, and `trash` on *macOS* or *Windows*. (The trash CLIs must usually be
  installed.)
- `showInSystemExplorer`: Reveals the current file in the system explorer, such
  as macOS Finder. (Currently only on macOS, PRs welcome.)

The following applies to all commands above:
1. If no extension has been provided, uses the extension of the original file.
   (Everything after the first non-leading dot is treated as the extension; this
   behavior can be disabled with the config `fileOperations.autoAddExt = false`.)
2. If the new filename includes a `/`, the new file is placed in the respective
   subdirectory, creating any non-existing intermediate folders.
3. All movement and renaming commands update `import` statements to the renamed
   file (if the LSP supports `workspace/willRenameFiles`).

### Copy operations
- `copyFilename`: Copy the filename.
- `copyFilepath`: Copy the absolute filepath.
- `copyFilepathWithTilde`: Copy the absolute filepath, replacing the home
  directory with `~`.
- `copyRelativePath`: Copy the relative filepath.
- `copyDirectoryPath`: Copy the absolute directory path.
- `copyRelativeDirectoryPath`: Copy the relative directory path.
- `copyFileItself`: Copies the file itself. This means you can paste it into
  the browser or file manager. (Currently only on macOS, PRs welcome.)

All commands use the system clipboard.

### File navigation
`.navigateToFileInFolder("next"|"prev")`: Move to the next/previous file in the
current folder of the current file, in alphabetical order.
- If `snacks.nvim` is installed, displays a cycling notification.

## Why the name "Genghis"?
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch), an older vimscript
plugin with a similar goal. As opposed to childless eunuchs, it is said that
Genghis Khan [has fathered thousands of
children](https://allthatsinteresting.com/genghis-khan-children).

## About the author
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

- [Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'> <img height='36'
style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
