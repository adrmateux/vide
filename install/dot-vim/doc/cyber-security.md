# Findind Cyber security threats in vim code/plugins

## Manual Code Review

The most reliable method is to read the code yourself:

```
" Check what the script does on startup
:e ~/.vim/pack/completion/opt/vim-mucomplete/plugin/mucomplete.vim

" Look for suspicious patterns:
" - system(), execute(), eval() calls
" - Network operations (curl, wget, socket connections)
" - File operations outside expected scope
" - Obfuscated code or encoded strings
" - Auto-execution on events (autocmd)
```

## Check Plugin Sources
Official repositories: Prefer plugins from well-known sources (vim.org, GitHub with many stars/watchers)
Active maintenance: Check last update date and issue responses
Community trust: Look for plugins mentioned in Vim wikis, popular dotfiles
Author reputation: Research the author's other work

# Review Installation Points
Look at these critical files in each plugin:
```
# Key files to review:
plugin/*.vim      # Runs automatically when Vim starts
autoload/*.vim    # Loaded on-demand (safer)
ftplugin/*.vim    # Filetype-specific (safer)
syntax/*.vim      # Syntax highlighting (safer)
```

# Specific Red Flags to Watch For

```
" SUSPICIOUS patterns:

" 1. Network calls without clear purpose
:silent !curl http://suspicious-site.com

" 2. Arbitrary code execution
:execute system('some_command')
:eval(string_from_network)

" 3. File operations in unexpected locations
:call writefile(data, '/etc/passwd')
:!rm -rf ~/*

" 4. Obfuscated or base64 encoded commands
:execute base64_decode('...')

" 5. Background processes
:silent !nohup malicious_script &

" 6. Reading sensitive files
:let data = readfile($HOME . '/.ssh/id_rsa')
````

## . For Your Current Plugins
Let me help you check your loaded plugins:
```
# Check what's loaded
find ~/.vim/pack -name "*.vim" -type f | head -20

# Search for potentially dangerous functions across all plugins
grep -r "system\|execute\|eval\|curl\|wget" ~/.vim/pack/*/opt/*/plugin/
```

## 6. Safe Practices

- Use opt instead of start: Your plugins are in opt/ (good!), meaning they only load when explicitly called with packadd

- Sandbox untrusted code:
```
" Run in a restricted environment
:set secure
:set nomodeline  " Prevents malicious modelines in files
```

- Version control your config:
```
cd ~/.vim
git init
git add .
git commit -m "Current vim config"
# Now you can track any unexpected changes
```

- Use plugin managers with lockfiles: Consider using vim-plug, Vundle, or Pathogen which track plugin versions

## Specific to Your Plugins
Looking at your setup:

coc.nvim: Very popular, actively maintained, from GitHub (good) <<<------------------ Fishy system calls. Needs to take a look.
copilot.vim: Official GitHub plugin (safe)
vim-mucomplete: Well-known completion plugin (safe)
clang_complete: Established C++ completion (safe)
CCTree: Old but simple cscope visualization (safe)

## Quick Security Audit Commands

```
# Find all executable permissions (shouldn't be many)
find ~/.vim -type f -executable

# Check for wget/curl usage
grep -r "wget\|curl" ~/.vim/pack/

# Look for system calls
grep -r "system(" ~/.vim/pack/

# Check for external command execution
grep -r "silent !" ~/.vim/pack/
```

## Runtime Protection
Add to your vimrc:
```
" Disable modelines (security risk in opened files)
set nomodeline

" Restrict commands in non-vimrc files
set secure

" Don't allow writing to arbitrary files
set nowritebackup in untrusted contexts
```

##  For New Plugins - Checklist
Before installing:

 Check GitHub stars/forks/last update
 Read the plugin's main file (plugin/*.vim)
 Search for: system, !, execute, network calls
 Check open issues for security concerns
 Verify SSL when downloading: git clone https://...
 Review autoload files for unexpected behavior
Bottom line: Your current plugins (coc.nvim, copilot.vim, mucomplete) are from trusted sources and widely used. For maximum safety, periodically review any plugin that has plugin/*.vim files since those execute automatically.

## TODO - Findings
The search bellow provokes a very weird result
```
grep -irn "\:silent !curl"
```

