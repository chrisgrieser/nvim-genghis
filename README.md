# nvim-genghis
Convenience file operations for neovim, written in lua. 

> __Note__  
> Previously, "genghis" was spelled wrong at various places, including the GitHub-URL and the package name. :see_no_evil: By fixing that, the repo-address and package name have changed. Sorry for the inconvenience!

---

<!--toc:start-->
- [How is this different from `vim.eunuch`?](#how-is-this-different-from-vimeunuch)
- [Installation and setup](#installation-and-setup)
- [Available commands](#available-commands)
- [Why that name](#why-that-name)
- [About me](#about-me)
<!--toc:end-->

## How is this different from `vim.eunuch`?
- Written 100% in lua. Uses only vim-commands or lua os-modules and no shell commands to it works on every platform.
- Uses up-to-date nvim features like `vim.ui.input` or `vim.notify`. This means you can get nicer input fields via plugins like [dressing.nvim](https://github.com/stevearc/dressing.nvim), and nicer confirmation notices with plugins like [nvim-notify](https://github.com/rcarriga/nvim-notify), if they are installed and setup.
- Some small improvements like automatically keeping the extensions when no extension is given, or moving to the trash instead of removing files.

## Installation and setup

```lua
-- Recommended (Packer)
use {"chrisgrieser/nvim-genghis", requires = "stevearc/dressing.nvim"}

-- if you do not care about nice input fields
use "chrisgrieser/nvim-genghis"
```

`nvim-genghis` (and `dressign.nvim`) require no `.setup()` function. Just create keybindings for the commands you want to use:

```lua
local keymap = vim.keymap.set
local genghis = require("genghis")
keymap("n", "<leader>yp", genghis.copyFilepath)
keymap("n", "<leader>yn", genghis.copyFilename)
keymap("n", "<leader>cx", genghis.chmodx)
keymap("n", "<leader>rf", genghis.renameFile)
keymap("n", "<leader>nf", genghis.createNewFile)
keymap("n", "<leader>yf", genghis.duplicateFile)
keymap("n", "<leader>df", function () genghis.trashFile{trashLocation = "your/path"} end) -- default: '$HOME/.Trash'.
keymap("x", "<leader>x", genghis.moveSelectionToNewFile)
```

## Available commands
- `.copyFilepath`: Copy the absolute file path. When `clipboard="unnamed[plus]"`, copies to the `+` register, otherwise to `"`.
- `.copyFilename`: Copy the file name. When `clipboard='unnamed[plus]`, copies to the `+` register, otherwise to `"`.
- `.chmodx`: Makes current file executable. Equivalent to `chmod +x`.
- `.renameFile`: Rename the current file. If no extension is provided, keeps the current file extension.
- `.createNewFile`: Create a new file. If no extension is provided, uses the extension of the current file.
- `.duplicateFile`: Duplicate the current file. If no extension is provided, keeps the current file extension.
- `.trashFile`: Move the current file to `$HOME/.Trash`. Can optionally be passed a table to change the trash location: `.trashFile{trashLocation = "your/path/"}`. Note that any existing files in the trash location with the same name may be overwritten.
- `.moveSelectionToNewFile`: Visual Line Mode Command. Prompts for a new file name and moves the current selection to that new file. (Note that the selection is moved linewise.)

## Why that name
A nod to [vim.eunuch](https://github.com/tpope/vim-eunuch) - as opposed to childless eunuchs, it is said that Genghis Khan [has fathered thousands of children](https://allthatsinteresting.com/genghis-khan-children).

<!-- vale Google.FirstPerson = NO --> <!-- vale Microsoft.FirstPerson = NO -->
## About me
In my day job, I am a sociologist studying the social mechanisms underlying the digital economy. For my PhD project, I investigate the governance of the app economy and how software ecosystems manage the tension between innovation and compatibility. If you are interested in this subject, feel free to get in touch.

__Profiles__
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [GitHub](https://github.com/chrisgrieser/)
- [Twitter](https://twitter.com/pseudo_meta)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)


__Donate__  
<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

---

This is my first neovim plugin, so suggestions for improvements are welcome.
