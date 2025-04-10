source ~/.vim/helpers.vim


function! Vide_version()
  let g:Vide_version="0.1.0
endfunction


function! Start_ide(...)
  echo "Starting IDE support"
  echo "Current Working Directory:"
  pwd 
  " --- core editor settings ---
  nnoremap j gj
  nnoremap k gk
  nnoremap <Down> gj
  nnoremap <Up> gk
  set number
  set mouse=a
  colorscheme desert

  let g:ide_chain=confirm('Select IDE chain:',"&no chain\n&clangd complete\nc&oc",1)
  if g:ide_chain == 1
    " No chain
    echo "No ide chain"
  
  elseif g:ide_chain == 2
    " clang_complete
    echo "Loading clang_complete ..."
    call Vide_common_ide_settings()
    call Clang_complete_plugin()
 
  elseif g:ide_chain == 3
    " coc.nvim
    echo "Loading coc.nvim ..."
    call Vide_common_ide_settings()
    call Coc_nvim_plugin()

  else
    echo "ERROR: Undefined IDE chain selected."
  endif

  let g:ide_ai=confirm('Select AI:',"&no AI\n&copilot",1)
  if g:ide_ai == 1
    " No AI
    echo "No AI"
  
  elseif g:ide_ai == 2
    " copilot
    echo "Loading Copilot AI ..."
    call Vide_AI_Copilot()

  else
    echo "ERROR: Undefined AI selected."
  endif

  " Misc function mappings
  " Creation of UML diagrams. Requires: plantuml
  "map <C-m>z :/@startuml/,/@enduml/w! .tmp.uml.txt<CR>:!reset<CR>:!plantuml .tmp.uml.txt<CR>:!rm .tmp.uml.txt<CR>:!eog 
  map <C-m>z :call GenerateUMLDiagram()<CR>

endfunction


function Vide_common_ide_settings()
  " https://github.com/octol/vim-cpp-enhanced-highlight
   packadd vim-cpp-enhanced-highlight
  
  " TODO: find out where to place termdebug stuff
  let g:termdebugger='gdb-multiarch'

  " DEPRECATED: use lang c by default
  " call Vimide_lang_c() 
 
  call Load_tags_db()
  call Load_CCTreeDB()

  packadd termdebug
  let g:termdebugger='gdb-multiarch'
  call Netrw_client()
  call StatusLine_settings()

endfunction


function! Clang_complete_plugin()
  packadd clang_complete
  " The following line assumes `brew install llvm` in macOS
  " For clang-complete
  let g:clang_library_path = '/usr/lib/llvm-14/lib/libclang-14.so.1'
  let g:clang_user_options = '-std=c++11'
  let g:clang_complete_auto = 1
endfunction


function! Coc_nvim_plugin()
  packadd coc.nvim
  let g:coc_disable_startup_warning = 1
  source ~/.vim/coc-nvim.vim
endfunction


function! Netrw_client()
  "Execute command on file
  " map <C-r> mf mx - TODO: este shortcut pega con redo
  let g:netrw_list_hide='.*\.d$,.*\.o$,.*\.swp$'
  let g:netrw_hide = 1
  let g:netrw_browse_split=3
  nmap kk :0tabnew<CR>
  nmap ko :bd<CR>
endfunction


function! Netrw_server()
  " Press <C-CR> will open file on a specific servername, tab 1, window 1. 
  " After using it, all subsequent <CR> will do the same
  let g:netrw_servername=$VI_SERVER
  let g:netrw_browse_split=[$VI_SERVER,0,0]
  "Execute command on file
  map <C-f> mf mx
  nmap kk :silent! !vsx :0tabnew<CR><C-l>:redraw!<CR>
  nmap ko :silent! !vsx :bd<CR><C-l>:redraw!<CR>

  let g:netrw_list_hide='.*\.d$,.*\.o$,.*\.swp$'
  let g:netrw_hide = 1
  let g:netrw_preview=0
endfunction


function! StatusLine_settings()
  set laststatus=2
  set statusline=%t       "tail of the filename
  set statusline+=[%{strlen(&fenc)?&fenc:'none'}, "file encoding
  set statusline+=%{&ff}] "file format
  set statusline+=%h      "help file flag
  set statusline+=%m      "modified flag
  set statusline+=%r      "read only flag
  set statusline+=%y      "filetype
  set statusline+=%=      "left/right separator
  set statusline+=%c,     "cursor column
  set statusline+=%l/%L   "cursor line/total lines
  set statusline+=\ %P    "percent through file
endfunction


function! Load_tags_db()
  if !exists("g:tags_db_loaded") 
    " ctags
    map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
    map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
    
    map <C-F10> :call Load_tags_db()<CR>
    let g:tags_db_loaded = 1
    
    " To see configuration for ctags and cscope interaction, see:
    " ~/workspace/kb/vimide/install/dot-vim/plugin/cscope_maps.vim    
   else
    :!cscope -Rbq
    cscope reset
  endif
endfunction


function! Load_CCTreeDB()
  " CCTree  
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


function! Vimide_clipboard_layout()
  set nonumber
  set signcolumn=no
endfunction


function! Vide_AI_Copilot()
  packadd copilot.vim

  " Mappings: ALT ], ALT [ not working. Use then:
  imap <C-i>n <Plug>(copilot-next)
  imap <C-i>p <Plug>(copilot-previous)
  imap <C-i>d <Plug>(copilot-dismiss)
  imap <C-i>s <Plug>(copilot-suggest)
  imap <C-i>w <Plug>(copilot-accept-word)

  " Enable or disable Copilot on a per-buffer basis
  let g:copilot_buffer_state = {}
  augroup copilot_buffer
    autocmd!
    autocmd BufEnter * :call Copilot_Control()
    " autocmd BufLeave * let g:copilot_buffer_state[bufnr('%')] = (get(g:copilot_buffer_state, bufnr('%'), 0) == 1 ? 1 : 0)
  augroup END

  " Enable Copilot in the current buffer
  command! CopilotEnable let g:copilot_buffer_state[bufnr('%')] = 1 | Copilot enable
  " Disable Copilot in the current buffer
  command! CopilotDisable let g:copilot_buffer_state[bufnr('%')] = 0 | Copilot disable

endfunction


function! Copilot_Control()
  if get(g:copilot_buffer_state, bufnr('%'), 0) == 1 
    Copilot enable
    echo "Copilot activated for the current buffer" 
  else
    Copilot disable
    echo "Copilot deactivated for the current buffer" 
  endif
endfunction
