# nvim-ghengis
Convenience file operations for neovim written in lua. 

<!--toc:start-->
- [How is this different from `vim.eunuch`?](#how-is-this-different-from-vimeunuch)
- [Installation and Setup](#installation-and-setup)
- [Available Commands](#available-commands)
- [Why that name?](#why-that-name)
<!--toc:end-->

## How is this different from `vim.eunuch`?
- Written 100% in lua.
- Uses up-to-date nvim features like `vim.ui.input` or `vim.notify`. This means you can get nicer input fields via plugins like [dressing.nvim](https://github.com/stevearc/dressing.nvim), and nice confirmation notices with plugins like [nvim-notify](https://github.com/rcarriga/nvim-notify), if they are installed and setup.
- Some minor improvements like automatically keeping the extensions when no extension is given, or moving to the trash instead of removing files.
- Except for `trashFile` and `chmodx` only vim commands or lua os-modules are used to keep shell requirements to a minimum. 

## Installation and Setup

```lua
-- Packer
use "chrisgrieser/nvim-ghengis"
```

`ghengis` requires no `.setup()` function. Just create keybindings for the commands you want to use.

```lua
local ghengis = require("ghengis")
local keymap = vim.keymap.set
keymap("n", "<leader>yp", ghengis.copyFilepath)
keymap("n", "<leader>yn", ghengis.copyFilename)
keymap("n", "<leader>cx", ghengis.chmodx)
keymap("n", "<leader>rf", ghengis.renameFile)
keymap("n", "<leader>nf", ghengis.createNewFile)
keymap("n", "<leader>yf", ghengis.duplicateFile)
keymap("n", "<leader>df", ghengis.trashFile) -- requires macOS or Linux `mv` command
keymap("x", "<leader>x", ghengis.moveSelectionToNewFile)
```

## Available Commands
- `ghengis.copyFilepath`: Copy the absolute file path. When `clipboard='unnamed[plus]`, copies to the `+` register, otherwise to `"`.
- `ghengis.copyFilename`: Copy file name. When `clipboard='unnamed[plus]`, copies to the `+` register, otherwise to `"`.
- `ghengis.chmodx`: Run `chmod +x` on the current file.
- `ghengis.renameFile`: Rename the current file. If no extension is provided, will keep the current file extension.
- `ghengis.createNewFile`: Create a new file. If no extension is provided, will keep use the extension of the current file.
- `ghengis.duplicateFile`: Duplicate the current file. If no extension is provided, will keep the current file extension.
- `ghengis.trashFile`: Move the current file to `$HOME/.Trash`. Can optionally be passed a table to change the trash location: `ghengis.trashFile{trashLocation = "your/path/"}`. (Requires macOS or Linux, since using `mv`.) 
- `ghengis.moveSelectionToNewFile`: Visual Mode Command. Prompts for a new file name and moves the current selection to that new file.

## Why that name?
A tribute to [vim.eunuch](https://github.com/tpope/vim-eunuch) – as opposed to childless eunuchs, it is said that [Ghengis Khan has fathered thousands of children](https://allthatsinteresting.com/genghis-khan-children).
