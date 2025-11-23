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
" ============================================================================
" AI Selection and Loading
" ============================================================================
function! s:Select_and_load_AI()
  " Initialize global AI tracking if not exists
  if !exists('g:vide_buffer_ai_type')
    let g:vide_buffer_ai_type = {}
  endif
  if !exists('g:vide_buffer_ai_state')
    let g:vide_buffer_ai_state = {}
  endif
  
  " Set default AI for startup
  let g:ide_ai = confirm('Select Default AI:', "&no AI\n&copilot\n&llama.vim", 1)
  
  " Load all AI plugins at startup
  if g:ide_ai == 1
    echo "No default AI"
  elseif g:ide_ai == 2
    echo "Loading Copilot AI as default..."
    call s:Load_AI_plugins('copilot')
  elseif g:ide_ai == 3
    echo "Loading Llama.vim as default..."
    call s:Load_AI_plugins('llama')
  else
    echo "ERROR: Undefined AI selected."
    return
  endif
  
  " Load both AI plugins to allow per-buffer switching
  if g:ide_ai == 2
    call s:Load_AI_plugins('llama')
  elseif g:ide_ai == 3
    call s:Load_AI_plugins('copilot')
  endif
  
  " Setup unified AI control
  call s:Setup_unified_AI_control()
endfunction

" ============================================================================
" Miscellaneous Mappings
" ============================================================================
function! s:Setup_misc_mappings()
  " UML diagram generation (requires plantuml)
  nmap <C-m>z :call GenerateUMLDiagram()<CR>
  
  "Execute selected code as python code
  xnoremap <leader>p :w !python3<cr>
  
  "Execute selected code as c++ code
  xnoremap <leader>c :w !g++ -o main -x c++ - ; ./main<cr>

  "Execute selected code as c++ code
  xnoremap <leader>s :w !bash<cr>

  "Execute selected code as jshell/java code
  xnoremap <leader>j :w !jshell -<cr>


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
  
  set statusline+=%{StatusAI()}                  " AI status (per-buffer)
  
  set statusline+=%=                             " left/right separator
  set statusline+=%c,                            " cursor column
  set statusline+=%l/%L                          " cursor line/total lines
  set statusline+=\ %P                           " percent through file
endfunction

function! StatusAI()
  if !exists('g:vide_buffer_ai_type')
    return '[ai:?]'
  endif
  
  let l:bufnr = bufnr('%')
  let l:ai_type = s:Get_buffer_AI_type(l:bufnr)
  let l:ai_state = s:Get_buffer_AI_state(l:bufnr)
  
  if l:ai_type == 1
    return '[ai:none]'
  elseif l:ai_type == 2
    return '[ai:copilot:' . l:ai_state . ']'
  elseif l:ai_type == 3
    return '[ai:llama:' . l:ai_state . ']'
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
" ============================================================================
" AI Assistants - Plugin Loading
" ============================================================================

" Load AI plugins (can be called multiple times safely)
function! s:Load_AI_plugins(ai_type)
  if a:ai_type == 'copilot'
    call s:Load_Copilot_plugin()
  elseif a:ai_type == 'llama'
    call s:Load_Llama_plugin()
  endif
endfunction

" GitHub Copilot AI Assistant
function! s:Load_Copilot_plugin()
  if exists('g:copilot_loaded')
    return
  endif
  
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
  
  let g:copilot_loaded = 1
endfunction

" Llama.vim AI Assistant
function! s:Load_Llama_plugin()
  if exists('g:llama_loaded')
    return
  endif
  
  " Start llama-server if not already running
  call s:Start_llama_server()
  
  " Configure and load plugin
  let g:llama_config = { 'show_info': 0 }
  packadd llama.vim
  
  let g:llama_loaded = 1
endfunction

" Setup unified AI control system
function! s:Setup_unified_AI_control()
  " Create autocommand group for AI control
  augroup vide_ai_control
    autocmd!
    autocmd BufEnter * call s:AI_Buffer_Control()
  augroup END
  
  " Define unified commands
  command! -nargs=0 AIEnable call s:AI_Enable()
  command! -nargs=0 AIDisable call s:AI_Disable()
  command! -nargs=0 AIChange call s:AI_Change()
endfunction

" ============================================================================
" Deprecated - Kept for compatibility
" ============================================================================
function! Vide_AI_Copilot()
  call s:Load_Copilot_plugin()
endfunction

function! Vide_AI_LlamaVim()
  call s:Load_Llama_plugin()
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

function! s:Get_buffer_AI_type(bufnr)
  if !exists('g:vide_buffer_ai_type')
    let g:vide_buffer_ai_type = {}
  endif
  
  " Return buffer-specific AI type, or default to global setting
  if has_key(g:vide_buffer_ai_type, a:bufnr)
    return g:vide_buffer_ai_type[a:bufnr]
  else
    " Set default based on global ide_ai
    if exists('g:ide_ai')
      let g:vide_buffer_ai_type[a:bufnr] = g:ide_ai
      return g:ide_ai
    else
      let g:vide_buffer_ai_type[a:bufnr] = 1  " no AI
      return 1
    endif
  endif
endfunction

function! s:Get_buffer_AI_state(bufnr)
  if !exists('g:vide_buffer_ai_state')
    let g:vide_buffer_ai_state = {}
  endif
  
  " Return buffer-specific AI state (0=disabled, 1=enabled)
  return get(g:vide_buffer_ai_state, a:bufnr, 0)
endfunction

function! s:Set_buffer_AI_type(bufnr, ai_type)
  if !exists('g:vide_buffer_ai_type')
    let g:vide_buffer_ai_type = {}
  endif
  let g:vide_buffer_ai_type[a:bufnr] = a:ai_type
endfunction

function! s:Set_buffer_AI_state(bufnr, state)
  if !exists('g:vide_buffer_ai_state')
    let g:vide_buffer_ai_state = {}
  endif
  let g:vide_buffer_ai_state[a:bufnr] = a:state
endfunction

" ============================================================================
" Unified AI Buffer Control
" ============================================================================
function! s:AI_Buffer_Control()
  let l:bufnr = bufnr('%')
  let l:ai_type = s:Get_buffer_AI_type(l:bufnr)
  let l:ai_state = s:Get_buffer_AI_state(l:bufnr)
  
  " Control Copilot
  if l:ai_type == 2 && l:ai_state == 1
    silent! Copilot enable
  else
    silent! Copilot disable
  endif
  
  " Control Llama.vim
  if l:ai_type == 3 && l:ai_state == 1
    silent! LlamaEnable
  else
    silent! LlamaDisable
  endif
endfunction

function! s:AI_Enable()
  let l:bufnr = bufnr('%')
  let l:ai_type = s:Get_buffer_AI_type(l:bufnr)
  
  if l:ai_type == 1
    echo "No AI selected for this buffer. Use :AIChange to select one."
    return
  endif
  
  call s:Set_buffer_AI_state(l:bufnr, 1)
  call s:AI_Buffer_Control()
  
  if l:ai_type == 2
    echo "Copilot enabled in buffer " . l:bufnr
  elseif l:ai_type == 3
    echo "Llama.vim enabled in buffer " . l:bufnr
  endif
endfunction

function! s:AI_Disable()
  let l:bufnr = bufnr('%')
  let l:ai_type = s:Get_buffer_AI_type(l:bufnr)
  
  call s:Set_buffer_AI_state(l:bufnr, 0)
  call s:AI_Buffer_Control()
  
  if l:ai_type == 1
    echo "No AI to disable"
  elseif l:ai_type == 2
    echo "Copilot disabled in buffer " . l:bufnr
  elseif l:ai_type == 3
    echo "Llama.vim disabled in buffer " . l:bufnr
  endif
endfunction

function! s:AI_Change()
  let l:bufnr = bufnr('%')
  let l:current_ai = s:Get_buffer_AI_type(l:bufnr)
  
  " Get user selection
  let l:choice = confirm('Select AI for this buffer:', "&no AI\n&copilot\n&llama.vim", l:current_ai)
  
  " Exit if cancelled
  if l:choice == 0
    echo "AI change cancelled."
    return
  endif
  
  " Exit if same as current
  if l:choice == l:current_ai
    echo "Already using this AI in this buffer."
    return
  endif
  
  " Load AI plugin if not already loaded
  if l:choice == 2
    call s:Load_AI_plugins('copilot')
  elseif l:choice == 3
    call s:Load_AI_plugins('llama')
  endif
  
  " Set new AI type for this buffer
  call s:Set_buffer_AI_type(l:bufnr, l:choice)
  
  " Ask if user wants to enable it
  if l:choice != 1
    let l:enable = confirm('Enable AI in this buffer?', "&Yes\n&No", 1)
    if l:enable == 1
      call s:Set_buffer_AI_state(l:bufnr, 1)
    else
      call s:Set_buffer_AI_state(l:bufnr, 0)
    endif
  else
    call s:Set_buffer_AI_state(l:bufnr, 0)
  endif
  
  " Apply changes
  call s:AI_Buffer_Control()
  
  " Report result
  if l:choice == 1
    echo "No AI selected for buffer " . l:bufnr
  elseif l:choice == 2
    echo "Switched to Copilot in buffer " . l:bufnr . " (" . (s:Get_buffer_AI_state(l:bufnr) ? "enabled" : "disabled") . ")"
  elseif l:choice == 3
    echo "Switched to Llama.vim in buffer " . l:bufnr . " (" . (s:Get_buffer_AI_state(l:bufnr) ? "enabled" : "disabled") . ")"
  endif
endfunction

" ============================================================================
" Deprecated Functions - Kept for compatibility
" ============================================================================
function! s:Setup_AI_buffer_control(ai_type)
  " Deprecated - now handled by unified control
endfunction

function! Copilot_Control()
  " Deprecated - now handled by s:AI_Buffer_Control()
endfunction

function! Llama_Control()
  " Deprecated - now handled by s:AI_Buffer_Control()
endfunction
