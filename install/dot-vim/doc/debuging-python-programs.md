You’ve got a few solid ways to debug Python from Vim—ranging from quick-and-dirty `pdb` in the terminal to full-on GUI-like debugging with plugins. Below are practical workflows, with exact commands and config snippets so you can be productive right away.

***

## 1) Quick & Reliable: Use Python’s built-in `pdb`

### Fast one-off breakpoint

Add a breakpoint where you want execution to pause:

```python
# Python 3.7+
breakpoint()

# Older versions or if you prefer explicit:
import pdb; pdb.set_trace()
```

Run your script under the debugger from Vim:

```vim
:!python -m pdb your_script.py
```

This opens the CLI debugger in your shell (still inside Vim). It’s simple, no setup, and works anywhere.

### Using Vim’s terminal buffer (keeps you in Vim)

```vim
:terminal python -m pdb your_script.py
```

*   You’ll get an interactive terminal pane inside Vim.
*   Use `<C-w>w` to switch between terminal and code windows.
*   You can map a shortcut, e.g.:
    ```vim
    nnoremap <leader>dp :terminal python -m pdb %<CR>
    ```
    This runs the current file under `pdb`.

### Minimal `pdb` command cheatsheet

Inside the debugger:

*   `l` (list): show source around current line
*   `n` (next): step over
*   `s` (step): step into
*   `c` (continue): run until next breakpoint
*   `b 42` (break): set breakpoint at line 42
*   `b mymodule.py:17`: file+line breakpoint
*   `cl` / `cl 1`: clear all / clear breakpoint #1
*   `p expr`: print expression
*   `! stmt`: execute Python statement in current frame
*   `where` or `bt`: stack trace
*   `q`: quit

### Tips

*   If you need nicer prompts & features, install **ipdb** or **pdbpp** (`pip install ipdb pdbpp`) and use:
    ```python
    import ipdb; ipdb.set_trace()
    ```
*   For flaky terminal sizing: `:set splitright` and `:belowright terminal ...` to place the pane predictably.

***

## 2) Full-featured debugging in Vim with **Vimspector** (classic Vim)

If you want breakpoints, variable windows, watch expressions, call stacks, step controls—use Vimspector.

### Install (vim-plug example)

```vim
call plug#begin('~/.vim/plugged')
Plug 'puremourning/vimspector'
call plug#end()

" Optional UI niceties
let g:vimspector_enable_mappings = 'HUMAN'
```

Run `:PlugInstall`.

### Configure a Python debug profile

Create `.vimspector.json` in your project root:

```json
{
  "configurations": {
    "Python: Launch": {
      "adapter": "debugpy",
      "configuration": {
        "name": "Python: Launch",
        "type": "python",
        "request": "launch",
        "program": "${workspaceRoot}/your_script.py",
        "python": "python",
        "args": ["--your-arg", "value"],
        "cwd": "${workspaceRoot}",
        "console": "integratedTerminal",
        "justMyCode": true
      }
    }
  }
}
```

> Vimspector uses **debugpy** under the hood; make sure it’s installed:

```bash
pip install debugpy
```

### Workflow

*   Open your file in Vim.
*   Set breakpoints: move cursor to a line → `:call vimspector#ToggleBreakpoint()`  
    (or press `<F9>` with the HUMAN mappings enabled).
*   Start debugging: `:VimspectorLaunch`
*   Common keys (HUMAN mappings):
    *   `<F5>` Continue
    *   `<F10>` Step Over
    *   `<F11>` Step Into
    *   `<F12>` Step Out
    *   `<F9>` Toggle Breakpoint
    *   `<Leader>di` Inspect variable under cursor
    *   `:VimspectorReset` to end the session
*   Side panes show Variables, Watches, Call Stack, Breakpoints.

### Pros & Cons

*   **Pros:** Real breakpoints, watch variables, stack frames, evaluate expressions—everything inside Vim.
*   **Cons:** A bit of setup, plus a JSON profile for each project.

***

## 3) Neovim users: **nvim-dap** (DAP-based)

If you’re on Neovim, `nvim-dap` + `debugpy` gives similar powers.

### Install (lazy.nvim example)

```lua
{
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "mfussenegger/nvim-dap-python"
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    require("dap-python").setup("python") -- path to python if needed

    -- Keymaps
    vim.keymap.set('n', '<F5>', dap.continue)
    vim.keymap.set('n', '<F10>', dap.step_over)
    vim.keymap.set('n', '<F11>', dap.step_into)
    vim.keymap.set('n', '<F12>', dap.step_out)
    vim.keymap.set('n', '<F9>', dap.toggle_breakpoint)
    vim.keymap.set('n', '<leader>du', dapui.toggle)
  end
}
```

Start with:

*   `:lua require('dap-python').test_method()` (Python tests) or
*   `:lua require('dap').continue()` for the current config.
*   Ensure `pip install debugpy`.

***

## 4) Attach to a running Python process (server-side debugging)

Useful for web apps or long-running workers.

### In your Python app

```python
import debugpy

debugpy.listen(("0.0.0.0", 5678))  # or ("localhost", 5678)
print("Debugger listening on 5678")
debugpy.wait_for_client()          # optional: pause until a client attaches

# Optional breakpoint
debugpy.breakpoint()
```

### In Vim (Vimspector attach config)

```json
{
  "configurations": {
    "Python: Attach": {
      "adapter": "debugpy",
      "configuration": {
        "name": "Python: Attach",
        "type": "python",
        "request": "attach",
        "connect": { "host": "localhost", "port": 5678 },
        "cwd": "${workspaceRoot}"
      }
    }
  }
}
```

Launch with `:VimspectorLaunch`, then interact as usual.

***

## 5) Bonus: Helpful Vim settings for Python debugging

```vim
" Easier pane navigation while debugging in terminal
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Keep code readable
set number
set relativenumber
set signcolumn=yes

" Quickly run current file with pdb
nnoremap <leader>dp :belowright 15split | terminal python -m pdb %<CR>
```

***

## When to use which

*   **Need something fast:** `pdb` via `:!python -m pdb` or `:terminal ...`. Add `breakpoint()` and go.
*   **Want proper breakpoints, variables, watch windows:** Vimspector (Vim) or `nvim-dap` (Neovim).
*   **Attach to servers / remote processes:** `debugpy` + Vimspector/Nvim-DAP.

***

If you tell me whether you’re on **classic Vim or Neovim**, and whether you prefer **no plugins** or you’re okay adding one, I can give you a ready-to-paste config tailored to your setup (including keymaps that won’t conflict with your current ones).

