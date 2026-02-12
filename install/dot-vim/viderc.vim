" ============================================================================
" Vide - Vim IDE Configuration
" ============================================================================
" Main configuration file for Vide (Vim Integrated Development Environment)
" Provides IDE features including completion, AI assistance, and debugging

source ~/.vim/helpers.vim
source ~/.vim/vide-ai.vim
source ~/.vim/vide-help.vim
source ~/.vim/vide-open-reference-helpers.vim

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
  call Select_and_load_AI()
  call s:Setup_misc_mappings()
  call StatusLine_settings()
endfunction

" ============================================================================
" Core Editor Settings
" ============================================================================
function! s:Setup_core_editor_settings()

  set display=truncate
  set hidden

  " Show the following hidded characters as configured (use `set list` to show
  " them. From experience with copy paste bash script from copilot).
  set listchars=tab:>-,trail:~,nbsp:_

  " Set system clipboard: https://vim.fandom.com/wiki/Accessing_the_system_clipboard
  set clipboard=unnamedplus

  " Problems with HOME/END/PGDN/PGUP if not set
  set term=xterm-256color

  " Dictionaries
  set dictionary+=/usr/share/dict/american-english
  set dictionary+=/usr/share/dict/spanish

  " The best color scheme so far
  colorscheme slate

  " Searchj options
  set ignorecase
  set smartcase

  "The split is bellow the current viewport
  set splitbelow

  "Netrw options:
  "window size
  let g:netrw_winsize = 20
  ":hide by default
  let g:netrw_hide = 1  
  "opens new tab when <cr> is pressed
  let g:netrw_browse_split = 3 
  "open preview window as a vertical split
  let g:netrw_preview = 1 
  let g:netrw_chgwin =2 
  let g:netrw_alto = 0 

  "TODO:ROLL BACK ALL USAGE OF ZSH: not safe, not posix, added value can be developed in bash
  set shell=/bin/zsh

  " Highlight search
  " set hlsearch

  "set nocompatible
  " set termguicolors
  " colorscheme peachpuff
  " show existing tab with 2 spaces width
  set tabstop=2
  " when indenting with '>', use 2 spaces width
  set shiftwidth=2
  " On pressing tab, insert 2 spaces
  set expandtab
  " set number

  " Solves the problem "Press ENTER or type command to continue" when using netrw to open file on a vimserver
  " , but adds 2 lines to ex cmdline 
  set cmdheight=1

  " More visibility when autocomplete file names on the :ex command prompt
  " It will show, e.g., the list of all files on a directory, the list of 
  " vim commands for a given bunch of letters ...
  set wildmode=longest,list,full
  set wildmenu

  " Usefull mappings
  " Write and delete buffer
  " NOTE: Don't capitalize the first letter -> E183: User defined commands must start with an uppercase letter
  :command Wbd :w|bd

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
  let g:ide_chain = confirm('Select IDE chain:', "&no chain\n&clangd complete\nc&oc\n&native\nc&ustom_1", 1)
  
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
  elseif g:ide_chain == 4
    echo "Loading native ..."
    call Vide_common_ide_settings()
    call Native_ide_completion()
  elseif g:ide_chain == 5
    echo "Loading custom_1 ..."
    call Vide_common_ide_settings()
    call Custom_1_ide_completion()
  else
    echo "ERROR: Undefined IDE chain selected."
  endif
endfunction

" ============================================================================
" Miscellaneous Mappings
" ============================================================================
function! s:Setup_misc_mappings()
  " UML diagram generation (requires plantuml)
  nmap <C-m>z :call GenerateUMLDiagram()<CR>
  
  "Execute selected code as python code - after select type "\p"
  xnoremap <leader>p :w !python3<cr>
  
  "Compile c++ code as you create it by typing  "<C-b><C-o>"
  inoremap <C-b>c <C-o>:execute ':w !g++ -o ' . expand("%:t:r") . ' -x c++ - ; ./' . expand("%:t:r")<CR>
  
  "Execute selected code as c++ code - after select type "\c"
  xnoremap <leader>c :w !g++ -o main -x c++ - ; ./main<cr>

  "Execute selected code as bash code - after select type "\s"
  xnoremap <leader>s :w !bash<cr>
  
  "Execute selected code as jshell/java code - after select type "\j"
  xnoremap <leader>j :w !jshell -<cr>
  
  "Execute markdown code snippet - after select type "\e"
  xnoremap <leader>e :call ExecuteMarkdownSnippet()<cr>
  
  " Show keyboard shortcuts in popup window
  nmap <C-F1> :call ShowShortcutsPopup()<CR>

  " Vimgrep/make errors navigation
  nmap cn :cnext <CR>
  nmap cp :cprevious <CR>
  nmap co :copen <CR>
  nmap cc :cclose <CR>

  " spell checker aspell - with language selection
  nmap <C-u> :call Aspell_check()<CR>

  "map 2 consecutive "j" as an <ESC> while editing/insert/append
  :imap jj <ESC> 

endfunction

" ============================================================================
" Spell Checking
" ============================================================================
function! Aspell_check()
  " Initialize language variable if not set
  if !exists('g:aspell_lang')
    let g:aspell_lang = 'en'
  endif
  
  " Prompt user to select language
  let l:choice = confirm('Select spell check language:', 
        \ "&English (en)\n&Spanish (es)\n&French (fr)\n&German (de)\n&Italian (it)\n&Portuguese BR (pt)\nOther (c&ustom)", 
        \ 1)
  
  if l:choice == 0
    echo "Spell check cancelled."
    return
  elseif l:choice == 1
    let g:aspell_lang = 'en'
  elseif l:choice == 2
    let g:aspell_lang = 'es'
  elseif l:choice == 3
    let g:aspell_lang = 'fr'
  elseif l:choice == 4
    let g:aspell_lang = 'de'
  elseif l:choice == 5
    let g:aspell_lang = 'it'
  elseif l:choice == 6
    let g:aspell_lang = 'pt_BR'
  elseif l:choice == 7
    " Custom language code
    let l:lang = input('Enter language code (e.g., en, es, fr): ')
    if empty(l:lang)
      echo "Spell check cancelled."
      return
    endif
    let g:aspell_lang = l:lang
  endif
  
  " Run aspell with selected language
  execute ':w!'
  execute ':!aspell --lang=' . g:aspell_lang . ' check %'
  execute ':e! %'
  
  echo "Spell check completed with language: " . g:aspell_lang
endfunction

" ============================================================================
" Execute Markdown Code Snippet
" ============================================================================
function! ExecuteMarkdownSnippet() range
  " Get the selected lines
  let l:lines = getline(a:firstline, a:lastline)
  
  " Check if first line contains language specification
  if l:lines[0] !~ '^```\w\+'
    echo "Error: Selection must start with ```<language>"
    return
  endif
  
  " Extract language from first line
  let l:lang = substitute(l:lines[0], '^```\(\w\+\).*', '\1', '')
  
  " Remove first line (```) and last line (```) if present
  let l:code_lines = l:lines[1:]
  if len(l:code_lines) > 0 && l:code_lines[-1] =~ '^```\s*$'
    let l:code_lines = l:code_lines[:-2]
  endif
  
  " Determine command based on language
  let l:cmd = ''
  if l:lang ==# 'python' || l:lang ==# 'python3' || l:lang ==# 'py'
    let l:cmd = 'python3'
  elseif l:lang ==# 'bash' || l:lang ==# 'sh' || l:lang ==# 'shell'
    let l:cmd = 'bash'
  elseif l:lang ==# 'c++' || l:lang ==# 'cpp' || l:lang ==# 'c'
    let l:cmd = 'g++ -o /tmp/mdsnippet -x c++ - && /tmp/mdsnippet'
  elseif l:lang ==# 'java'
    let l:cmd = 'jshell -'
  elseif l:lang ==# 'javascript' || l:lang ==# 'js'
    let l:cmd = 'node'
  elseif l:lang ==# 'ruby' || l:lang ==# 'rb'
    let l:cmd = 'ruby'
  elseif l:lang ==# 'perl' || l:lang ==# 'pl'
    let l:cmd = 'perl'
  elseif l:lang ==# 'php'
    let l:cmd = 'php'
  elseif l:lang ==# 'rust' || l:lang ==# 'rs'
    let l:cmd = 'rustc - -o /tmp/mdsnippet && /tmp/mdsnippet'
  elseif l:lang ==# 'go'
    let l:cmd = 'go run'
  elseif l:lang ==# 'plantuml' || l:lang ==# 'puml' || l:lang ==# 'uml'
    " Handle PlantUML diagrams
    call s:ExecuteMarkdownPlantUML(l:code_lines)
    return
  else
    echo "Error: Unsupported language '" . l:lang . "'"
    echo "Supported: python, bash, c++, java, javascript, ruby, perl, php, rust, go, plantuml"
    return
  endif
  
  " Create a temporary file with just the code (without backticks)
  let l:tmpfile = tempname()
  call writefile(l:code_lines, l:tmpfile)
  
  " Execute the code from the temporary file
  echo "Executing " . l:lang . " code..."
  execute '!cat ' . l:tmpfile . ' | ' . l:cmd
  
  " Clean up temporary file
  call delete(l:tmpfile)
endfunction

" ============================================================================
" Execute PlantUML from Markdown Snippet
" ============================================================================
function! s:ExecuteMarkdownPlantUML(code_lines)
  " Verify plantuml is installed
  if !executable('plantuml')
    echohl ErrorMsg
    echo "Error: plantuml is not installed or not in PATH"
    echohl None
    return
  endif
  
  if !executable('eog')
    echohl ErrorMsg
    echo "Error: eog is not installed or not in PATH"
    echohl None
    return
  endif
  
  " Extract diagram name from title if present
  let l:diagram_name = ''
  for l:line in a:code_lines
    let l:title_match = matchstr(l:line, '^\s*title\s\+\zs.\+')
    if !empty(l:title_match)
      let l:diagram_name = substitute(l:title_match, '[^a-zA-Z0-9_-]', '_', 'g')
      break
    endif
  endfor
  
  " Generate default name if no title found
  if empty(l:diagram_name)
    let l:diagram_name = 'markdown_uml_' . strftime('%Y%m%d_%H%M%S')
  endif
  
  let l:tmp_dir = '/tmp/'
  let l:uml_file = l:tmp_dir . l:diagram_name . '.uml'
  let l:output_file = l:tmp_dir . l:diagram_name
  
  " Write diagram content to temporary file
  call writefile(a:code_lines, l:uml_file)
  
  " Get desired output format
  let l:format = input("Diagram format (png/svg/eps/pdf/txt/utxt): ", "png")
  
  let l:valid_formats = ['png', 'svg', 'eps', 'pdf', 'vdx', 'xmi', 'scxml', 'html', 'txt', 'utxt', 'latex', 'latexNP']
  if index(l:valid_formats, l:format) == -1
    echohl ErrorMsg
    echo "Invalid format: " . l:format
    echohl None
    call delete(l:uml_file)
    return
  endif
  
  echo "\nGenerating: " . l:output_file . "." . l:format
  
  " Generate diagram with PlantUML
  let l:cmd = 'plantuml -t' . l:format . ' ' . shellescape(l:uml_file)
  let l:plantuml_output = system(l:cmd)
  
  " Check if output file was created
  let l:actual_format = (l:format == 'txt') ? 'atxt' : l:format
  let l:output_path = l:output_file . '.' . l:actual_format
  
  if !filereadable(l:output_path)
    echohl ErrorMsg
    echo "Error: Output file not created: " . l:output_path
    echo "PlantUML output: " . l:plantuml_output
    echohl None
    call delete(l:uml_file)
    return
  endif
  
  " Handle output based on format
  if l:format == "txt"
    silent execute 'r!cat ' . shellescape(l:output_file . '.a' . l:format)
  elseif l:format == "utxt"
    silent execute 'r!cat ' . shellescape(l:output_file . '.' . l:format)
  else
    " Open graphical diagram in viewer
    let l:viewer_cmd = 'eog ' . shellescape(l:output_file . '.' . l:format) . ' &'
    silent execute '!' . l:viewer_cmd
  endif
  
  " Cleanup temporary file
  call delete(l:uml_file)
  
  redraw!
  echohl MoreMsg
  echo "PlantUML diagram saved to: " . l:output_file . "." . l:format
  echohl None
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
function! Clang_complete_plugin()
  packadd clang_complete
  let g:clang_library_path = '/usr/lib/llvm-14/lib/libclang-14.so.1'
  let g:clang_user_options = '-std=c++11'
  let g:clang_complete_auto = 1
  echo "clang complete ide settings loaded!"
endfunction


function! Coc_nvim_plugin()
  packadd coc.nvim
  
  " coc.nvim in case of using this ide chain and vim is not 9.0.0438
  let g:coc_disable_startup_warning = 1
  source ~/.vim/coc-nvim.vim
  " Allow ins-completion to work with coc.nvim
  inoremap <expr> <C-y> pumvisible() ? "\<C-y>" : "\<C-e>"
  echo "coc.nvim ide settings loaded!"
endfunction


function! Custom_1_ide_completion()

  " Enable filetype detection and plugins
  filetype plugin on
  filetype indent on

  " ---------------------------
  " Basic Completion Settings
  " ---------------------------
  " Show completion menu
  set completeopt=menuone,noinsert,noselect

  " Use dictionary and thesaurus for text completion
  set dictionary+=/usr/share/dict/words
  " Uncomment and set your thesaurus file if available
  " set thesaurus+=~/.vim/thesaurus.txt

  " ---------------------------
  " Key Mappings for Completion
  " ---------------------------
  " Trigger keyword completion (current buffer)
  "inoremap <C-Space> <C-n>

  " Trigger omni completion (language-aware)
  "inoremap <C-x><C-o> <C-x><C-o>

  " Trigger file name completion
  "inoremap <C-x><C-f> <C-x><C-f>

  " Trigger spelling suggestions
  "inoremap <C-x>s <C-x>s

  " ---------------------------
  " Omni Completion Setup
  " ---------------------------
  " Enable omni completion for common languages
  autocmd FileType python setlocal omnifunc=python3complete#Complete
  autocmd FileType html,css,javascript setlocal omnifunc=htmlcomplete#Complete
  autocmd FileType java setlocal omnifunc=javacomplete#Complete

  " ---------------------------
  " Optional: Popup Menu Behavior
  " ---------------------------
  " Use Tab and Shift-Tab to navigate completion menu
  "inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  "inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  echo "custom_1 ide settings loaded!"
 
endfunction


function! Native_ide_completion()

  " Basic for omnicompletition -- REALLY??? Investigate
  filetype plugin on

  " ==== Autocomplete options ====
  " mucomplete - https://github.com/lifepillar/vim-mucomplete
  " for automatic completion
  " set completeopt+=menu
  set completeopt=menuone,noselect,noinsert

  " recommended settings:
  set shortmess+=c   " Shut off completion messages
  set belloff+=ctrlg " Add only if Vim beeps during completion
  let g:mucomplete#enable_auto_at_startup = 1 
  " Enabled and disabled at any time with :MUcompleteAutoToggle
  " Then, MUcomplete will kick in only when you pause typing. 
  let g:mucomplete#completion_delay = 2
  " The delay can be adjusted, of course: see :help mucomplete-customization.
  set noinfercase
  echo "Native ide settings loaded!"

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
  call s:Setup_core_editor_settings()
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
function! StatusLineMode()
  let l:mode = mode()
  let l:mode_text = ''
  if l:mode ==# 'n'
    let l:mode_text = 'NORMAL'
  elseif l:mode ==# 'i'
    let l:mode_text = 'INSERT'
  elseif l:mode ==# 'R'
    let l:mode_text = 'REPLACE'
  elseif l:mode ==# 'v'
    let l:mode_text = 'VISUAL'
  elseif l:mode ==# 'V'
    let l:mode_text = 'V-LINE'
  elseif l:mode ==# "\<C-V>"
    let l:mode_text = 'V-BLOCK'
  elseif l:mode ==# 'c'
    let l:mode_text = 'COMMAND'
  elseif l:mode ==# 's'
    let l:mode_text = 'SELECT'
  elseif l:mode ==# 'S'
    let l:mode_text = 'S-LINE'
  elseif l:mode ==# "\<C-S>"
    let l:mode_text = 'S-BLOCK'
  elseif l:mode ==# 't'
    let l:mode_text = 'TERMINAL'
  else
    let l:mode_text = l:mode
  endif
  " Add 1 space padding on each side
  return l:mode_text . ' '
endfunction

function! StatusLine_settings()
  " Define highlight group for mode display (white text on dark background)
  highlight StatusLineMode ctermfg=White ctermbg=DarkGray guifg=White guibg=#3a3a3a
  
  set laststatus=2
  set statusline=%#StatusLineMode#               " switch to mode highlight
  set statusline+=\ %{StatusLineMode()}          " space + current mode (function adds trailing space)
  set statusline+=%#StatusLine#                  " switch back to normal statusline
  set statusline+=\ %t                           " tail of the filename
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
