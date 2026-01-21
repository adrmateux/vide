# vide - A Simplified Vim-Based IDE

A minimal IDE that leverages vim as its primary editor, focused on simplicity while providing essential development tools.

## Philosophy

The core philosophy of vide is to keep things as simple as possible while maintaining essential IDE features for SW development.

## System Dependencies

Before using vide, ensure you have the following installed:
- **ctags** - For tag generation and navigation
- **cscope** - For source code browsing and cross-referencing

## Optional System Dependencies

**GNU Screen** - For resiliense against terminal shortages and multiuser/peer-review

## Quick Start

1. Clone the repository with all submodules:
   ```bash
   git clone --recursive https://github.com/your-repo/vide.git
   ```

2. Install system dependencies:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install ctags cscope

   # macOS
   brew install ctags cscope
   ```

3. Source the configuration in your `.vimrc`:
   ```vim
   source /path/to/vide/install/dot-vim/viderc.vim
   ```

## Plugins and Packages

### Git Plugins (Optional)

#### vim-cpp-enhanced-highlight
- **Description**: Advanced syntax highlighting for C/C++
- **Location**: `pack/git-plugins/opt/vim-cpp-enhanced-highlight`
- **Repository**: https://github.com/octol/vim-cpp-enhanced-highlight.git
- **Features**: Improved color schemes and syntax recognition for modern C/C++

### Completion Plugins (Optional)

#### clang_complete
- **Description**: Code completion using libclang
- **Location**: `pack/completion/opt/clang_complete`
- **Repository**: https://github.com/adrmateux/clang_complete.git
- **Branch**: `compatibility_with_ctags_cscope`
- **Features**: C/C++ code completion with clang support

#### coc.nvim
- **Description**: Conquer of Completion - A popular completion engine
- **Location**: `pack/completion/opt/coc.nvim`
- **Repository**: https://github.com/neoclide/coc.nvim.git
- **Branch**: `release`
- **Features**: Full-featured completion framework with LSP support

#### copilot.vim
- **Description**: GitHub Copilot integration for vim
- **Location**: `pack/completion/opt/copilot.vim`
- **Repository**: https://github.com/github/copilot.vim.git
- **Features**: AI-powered code suggestions and completions

#### vim-mucomplete
- **Description**: Minimalist completion plugin
- **Location**: `pack/completion/opt/vim-mucomplete`
- **Repository**: https://github.com/lifepillar/vim-mucomplete.git
- **Features**: Lightweight, chainable completions

#### vim-ai
- **Description**: AI assistant for vim
- **Location**: `pack/completion/opt/vim-ai`
- **Repository**: https://github.com/madox2/vim-ai.git
- **Features**: Integration with AI models for coding assistance

#### llama.vim
- **Description**: Llama language model integration for vim
- **Location**: `pack/completion/opt/llama.vim`
- **Repository**: https://github.com/ggml-org/llama.vim
- **Features**: Local LLM support for code suggestions

### IDE Tools (Optional)

#### CCTree
- **Description**: Call tree and call graph generator
- **Location**: `pack/ide-tools/opt/CCTree`
- **Repository**: https://github.com/hari-rangarajan/CCTree.git
- **Features**: Visualize function calls and call hierarchies

## Configuration Files

- **viderc.vim** - Main vim configuration for vide
- **coc-settings.json** - Configuration for CoC.nvim
- **vide-ai.vim** - AI-specific configurations
- **vide-help.vim** - Help system configuration
- **vide-shell-functions.sh** - Shell utility functions

## Managing Plugins

### Installing Optional Plugins

Plugins in the `pack/*/opt/` directories are optional and can be enabled in your vimrc:

```vim
packadd plugin-name
```

### Updating Submodules

To update all submodules to their latest versions:

```bash
git submodule update --remote --recursive
```

## Documentation

Additional documentation and guides are available in the `doc/` directory:
- `vide.md` - Main documentation
- `vide-shortcuts.md` - Keyboard shortcuts and keybindings
- `debuging.md` - Debugging setup and usage
- `cyber-security.md` - Security-related configurations

## License

See individual plugin repositories for their respective licenses.
