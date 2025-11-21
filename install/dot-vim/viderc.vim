" ============================================================================
" Vide - Vim IDE Configuration
" ============================================================================
" Main configuration file for Vide (Vim Integrated Development Environment)
" Provides IDE features including completion, AI assistance, and debugging

source ~/.vim/helpers.vim

" ============================================================================
" Version Information
" ============================================================================
function! Vide_version()
  let g:Vide_version="0.1.0"
endfunction

" ============================================================================
" Main Entry Point
" ============================================================================
function! Start_ide(...)
  echo "Starting IDE support"
  echo "Current Working Directory:"
  pwd 
  
  call s:Setup_core_editor_settings()
  call s:Select_and_load_IDE_chain()
  call s:Select_and_load_AI()
  call s:Setup_misc_mappings()
  call StatusLine_settings()
endfunction

" ============================================================================
" Core Editor Settings
" ============================================================================
function! s:Setup_core_editor_settings()
  " Navigation: make j/k move by visual lines
  nnoremap j gj
  nnoremap k gk
  nnoremap <Down> gj
  nnoremap <Up> gk
  
  " Display settings
  set number
  set mouse=a
  colorscheme desert
  set nowrap
  
  " Swap file location
  call system('mkdir -p ~/.cache/.vimswap')
  set directory^=$HOME/.cache/.vimswap//
endfunction

" ============================================================================
" IDE Chain Selection and Loading
" ============================================================================
function! s:Select_and_load_IDE_chain()
  let g:ide_chain = confirm('Select IDE chain:', "&no chain\n&clangd complete\nc&oc", 1)
  
  if g:ide_chain == 1
    echo "No ide chain"
  elseif g:ide_chain == 2
    echo "Loading clang_complete ..."
    call Vide_common_ide_settings()
    call Clang_complete_plugin()
  elseif g:ide_chain == 3
    echo "Loading coc.nvim ..."
    call Vide_common_ide_settings()
    call Coc_nvim_plugin()
  else
    echo "ERROR: Undefined IDE chain selected."
  endif
endfunction

" ============================================================================
" AI Selection and Loading
" ============================================================================
function! s:Select_and_load_AI()
  let g:ide_ai = confirm('Select AI:', "&no AI\n&copilot\n&llama.vim", 1)
  
  if g:ide_ai == 1
    echo "No AI"
  elseif g:ide_ai == 2
    echo "Loading Copilot AI ..."
    call Vide_AI_Copilot()
  elseif g:ide_ai == 3
    echo "Loading Llama.vim ..."
    call Vide_AI_LlamaVim()
  else
    echo "ERROR: Undefined AI selected."
  endif
endfunction

" ============================================================================
" Miscellaneous Mappings
" ============================================================================
function! s:Setup_misc_mappings()
  " UML diagram generation (requires plantuml)
  nmap <C-m>z :call GenerateUMLDiagram()<CR>
endfunction

" ============================================================================
" Common IDE Settings
" ============================================================================
function! Vide_common_ide_settings()
  " C++ syntax highlighting
  packadd vim-cpp-enhanced-highlight
  
  " Debugging support
  packadd termdebug
  let g:termdebugger = 'gdb-multiarch'
  
  " Code navigation
  call Load_tags_db()
  call Load_CCTreeDB()
  call Netrw_client()
endfunction

" ============================================================================
" Completion Plugins
" ============================================================================
  packadd clang_complete
  " The following line assumes `brew install llvm` in macOS
  " For clang-complete
  let g:clang_library_path = '/usr/lib/llvm-14/lib/libclang-14.so.1'
  let g:clang_user_options = '-std=c++11'
  let g:clang_complete_auto = 1
" ============================================================================
" Completion Plugins
" ============================================================================
function! Clang_complete_plugin()
  packadd clang_complete
  let g:clang_library_path = '/usr/lib/llvm-14/lib/libclang-14.so.1'
  let g:clang_user_options = '-std=c++11'
  let g:clang_complete_auto = 1
endfunction

function! Coc_nvim_plugin()
  packadd coc.nvim
  let g:coc_disable_startup_warning = 1
  source ~/.vim/coc-nvim.vim
  " Allow ins-completion to work with coc.nvim
  inoremap <expr> <C-y> pumvisible() ? "\<C-y>" : "\<C-e>"
endfunction

" ============================================================================
" File Browser (Netrw)
" ============================================================================
function! Netrw_client()
  let g:netrw_list_hide = '.*\.d$,.*\.o$,.*\.swp$'
  let g:netrw_hide = 1
  let g:netrw_browse_split = 3
  nmap kk :0tabnew<CR>
  nmap ko :bd<CR>
endfunction

function! Netrw_server()
  " Open files on a specific servername, tab 1, window 1
  let g:netrw_servername = $VI_SERVER
  let g:netrw_browse_split = [$VI_SERVER, 1, 1]
  let g:netrw_list_hide = '.*\.d$,.*\.o$,.*\.swp$'
  let g:netrw_hide = 1
  let g:netrw_preview = 0
  
  " Execute command on file
  map <C-f> mf mx
  nmap kk :silent! !vsx :0tabnew<CR><C-l>:redraw!<CR>
  nmap ko :silent! !vsx :bd<CR><C-l>:redraw!<CR>
endfunction

" ============================================================================
" Status Line
" ============================================================================
function! StatusLine_settings()
  set laststatus=2
  set statusline=%t                              " tail of the filename
  set statusline+=[%{strlen(&fenc)?&fenc:'none'} " file encoding
  set statusline+=,%{&ff}]                       " file format
  set statusline+=%h                             " help file flag
  set statusline+=%m                             " modified flag
  set statusline+=%r                             " read only flag
  set statusline+=%y                             " filetype
  
  if exists('g:copilot_buffer_state') || exists('g:ide_ai')
    set statusline+=%{StatusAI()}                " AI status
  endif
  
  set statusline+=%=                             " left/right separator
  set statusline+=%c,                            " cursor column
  set statusline+=%l/%L                          " cursor line/total lines
  set statusline+=\ %P                           " percent through file
endfunction

function! StatusAI()
  " Check for active AI configuration
  if exists('g:ide_ai')
    if g:ide_ai == 2 && exists('g:copilot_buffer_state')
      return '[ai:copilot:' . get(g:copilot_buffer_state, bufnr('%'), 0) . ']'
    elseif g:ide_ai == 3 && exists('g:llama_buffer_state')
      return '[ai:llama:' . get(g:llama_buffer_state, bufnr('%'), 0) . ']'
    elseif g:ide_ai == 1
      return '[ai:none]'
    endif
  endif
  
  " Fallback for legacy configuration
  if exists('g:copilot_buffer_state')
    return '[ai:copilot:' . get(g:copilot_buffer_state, bufnr('%'), 0) . ']'
  else
    return '[ai:?]'
  endif
endfunction

" ============================================================================
" Code Navigation (ctags, cscope, CCTree)
" ============================================================================
function! Load_tags_db()
  if !exists("g:tags_db_loaded")
    " ctags mappings
    map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
    map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
    map <C-F10> :call Load_tags_db()<CR>
    let g:tags_db_loaded = 1
  else
    " Rebuild cscope database
    :!cscope -Rbq
    cscope reset
  endif
endfunction

function! Load_CCTreeDB()
  packadd CCTree
  
  if !exists("g:cctreedb_loaded")
    :CCTreeLoadDB cscope.out
    let g:cctreedb_loaded = 1
  else
    :CCTreeUnLoadDB
    :CCTreeLoadDB cscope.out
  endif
  
  map <C-F11> :call Load_CCTreeDB()<CR>
endfunction

" ============================================================================
" Utility Functions
" ============================================================================
function! Vimide_clipboard_layout()
  set nonumber
  set signcolumn=no
endfunction

" ============================================================================
" AI Assistants
" ============================================================================
" GitHub Copilot AI Assistant
function! Vide_AI_Copilot()
  packadd copilot.vim
  
  " Keybindings - Use C-j instead of Tab for acceptance
  imap <silent><script><expr> <C-j> copilot#Accept("\<CR>")
  let g:copilot_no_tab_map = v:true
  
  " Navigation and control mappings
  imap <C-i>n <Plug>(copilot-next)
  imap <C-i>p <Plug>(copilot-previous)
  imap <C-i>d <Plug>(copilot-dismiss)
  imap <C-i>s <Plug>(copilot-suggest)
  imap <C-i>w <Plug>(copilot-accept-word)
  
  " Buffer state management
  call s:Setup_AI_buffer_control('copilot')
  
  " Commands for enabling/disabling
  command! AIEnable let g:copilot_buffer_state[bufnr('%')] = 1 | Copilot enable
  command! AIDisable let g:copilot_buffer_state[bufnr('%')] = 0 | Copilot disable
endfunction

" Llama.vim AI Assistant
function! Vide_AI_LlamaVim()
  " Start llama-server if not already running
  call s:Start_llama_server()
  
  " Configure and load plugin
  let g:llama_config = { 'show_info': 0 }
  packadd llama.vim
  
  " Buffer state management
  call s:Setup_AI_buffer_control('llama')
  
  " Commands for enabling/disabling
  command! AIEnable let g:llama_buffer_state[bufnr('%')] = 1 | LlamaEnable
  command! AIDisable let g:llama_buffer_state[bufnr('%')] = 0 | LlamaDisable
endfunction

" ============================================================================
" AI Helper Functions
" ============================================================================
function! s:Start_llama_server()
  let l:check = system('pgrep -x llama-server')
  if empty(l:check)
    call system('nohup llama-server --fim-qwen-3b-default > /dev/null 2>&1 &')
    echo "llama-server started."
  else
    echo "llama-server is already running."
  endif
endfunction

function! s:Setup_AI_buffer_control(ai_type)
  if a:ai_type == 'copilot'
    let g:copilot_buffer_state = {}
    augroup copilot_buffer
      autocmd!
      autocmd BufReadPost * call Copilot_Control()
      autocmd BufEnter * call Copilot_Control()
    augroup END
  elseif a:ai_type == 'llama'
    let g:llama_buffer_state = {}
    augroup llama_buffer
      autocmd!
      autocmd BufReadPost * call Llama_Control()
      autocmd BufEnter * call Llama_Control()
    augroup END
  endif
endfunction

" ============================================================================
" AI Buffer Control Functions
" ============================================================================
function! Copilot_Control()
  if !has_key(g:copilot_buffer_state, bufnr('%'))
    let g:copilot_buffer_state[bufnr('%')] = 0
  endif
  
  if get(g:copilot_buffer_state, bufnr('%'), 0) == 1
    Copilot enable
  else
    Copilot disable
  endif
endfunction

function! Llama_Control()
  if !has_key(g:llama_buffer_state, bufnr('%'))
    let g:llama_buffer_state[bufnr('%')] = 0
  endif
  
  if get(g:llama_buffer_state, bufnr('%'), 0) == 1
    LlamaEnable
  else
    LlamaDisable
  endif
endfunction

" ============================================================================
" AI Switching
" ============================================================================
function! s:Cleanup_current_AI()
  " Cleanup based on current AI selection
  if exists('g:ide_ai')
    if g:ide_ai == 2
      " Cleanup Copilot
      if exists('g:copilot_buffer_state')
        silent! Copilot disable
        augroup copilot_buffer
          autocmd!
        augroup END
        silent! delcommand AIEnable
        silent! delcommand AIDisable
      endif
    elseif g:ide_ai == 3
      " Cleanup Llama.vim
      if exists('g:llama_buffer_state')
        silent! LlamaDisable
        augroup llama_buffer
          autocmd!
        augroup END
        silent! delcommand AIEnable
        silent! delcommand AIDisable
      endif
    endif
  endif
endfunction

function! AIChange()
  " Get user selection
  let l:choice = confirm('Select AI:', "&no AI\n&copilot\n&llama.vim", get(g:, 'ide_ai', 1))
  
  " Exit if cancelled
  if l:choice == 0
    echo "AI change cancelled."
    return
  endif
  
  " Exit if same as current
  if exists('g:ide_ai') && g:ide_ai == l:choice
    echo "Already using this AI."
    return
  endif
  
  " Cleanup current AI
  call s:Cleanup_current_AI()
  
  " Set new AI
  let g:ide_ai = l:choice
  
  " Load new AI
  if g:ide_ai == 1
    echo "No AI selected"
  elseif g:ide_ai == 2
    echo "Switching to Copilot AI ..."
    call Vide_AI_Copilot()
    echo "Copilot AI loaded"
  elseif g:ide_ai == 3
    echo "Switching to Llama.vim ..."
    call Vide_AI_LlamaVim()
    echo "Llama.vim loaded"
  else
    echo "ERROR: Undefined AI selected."
  endif
endfunction

" Define the AIChange command
command! AIChange call AIChange()
