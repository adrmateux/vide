" ============================================================================
" Vide - AI Assistants Module
" ============================================================================
" AI assistant functionality for Vide (Vim Integrated Development Environment)
" Provides per-buffer AI control for Copilot and Llama.vim

let s:llama_pid_file = expand('~/.vim/.llama-server-pids')

" ============================================================================
" AI Selection and Loading
" ============================================================================
function! Select_and_load_AI()
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
  
  " Pre-load the alternative AI plugin (without starting server)
  " This allows per-buffer switching without delay
  if g:ide_ai == 2
    " Don't start llama-server yet, just load the plugin when needed
    " call s:Load_AI_plugins('llama')
  elseif g:ide_ai == 3
    call s:Load_AI_plugins('copilot')
  endif
  
  " Setup unified AI control
  call s:Setup_unified_AI_control()
endfunction

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
  
  " Navigation and control mappings
  imap <C-i>n <Plug>(copilot-next)
  imap <C-i>p <Plug>(copilot-previous)
  imap <C-i>d <Plug>(copilot-dismiss)
  imap <C-i>s <Plug>(copilot-suggest)
  imap <C-i>w <Plug>(copilot-accept-word)
  
  let g:copilot_loaded = 1
endfunction

" Llama.vim AI Assistant
function! LlamaRestart()
  if !KillLlamaServers()
    return
  endif
  call s:Start_llama_server()
endfunction

function! s:LlamaServerStartTime(pid) abort
  let l:stat_file = '/proc/' . a:pid . '/stat'
  if !filereadable(l:stat_file)
    return ''
  endif

  let l:stat_fields = split(substitute(join(readfile(l:stat_file), ' '), '^.*) ', '', ''), ' ')
  return len(l:stat_fields) > 19 ? l:stat_fields[19] : ''
endfunction

function! s:IsTrackedLlamaServer(pid, start_time, port) abort
  if a:pid !~# '^[1-9][0-9]*$' || a:start_time !~# '^[1-9][0-9]*$'
        \ || index(['8012', '8013', '8014'], a:port) < 0
    return 0
  endif

  let l:comm_file = '/proc/' . a:pid . '/comm'
  if !filereadable(l:comm_file) || get(readfile(l:comm_file), 0, '') !=# 'llama-server'
    return 0
  endif

  let l:cmdline_file = '/proc/' . a:pid . '/cmdline'
  let l:cmdline = system('tr "\\000" " " < ' . shellescape(l:cmdline_file))
  if l:cmdline !~# '\(^\|\s\)--port\s\+' . a:port . '\(\s\|$\)'
    return 0
  endif

  return s:LlamaServerStartTime(a:pid) ==# a:start_time
endfunction

function! s:StartTrackedLlamaServer(session, port, args) abort
  echom "Executing: llama-server " . a:args
  let l:pid_file = tempname()
  let l:server_cmd = 'printf "%s\n" "$$" > ' . shellescape(l:pid_file)
        \ . '; exec llama-server ' . a:args
  let l:cmd = 'screen -dmS ' . shellescape(a:session) . ' sh -c ' . shellescape(l:server_cmd)
  let l:output = system(l:cmd)
  if v:shell_error != 0
    call delete(l:pid_file)
    echohl ErrorMsg
    echom 'Failed to launch llama-server: ' . l:output
    echohl None
    return 0
  endif

  let l:pid = ''
  let l:start_time = ''
  for l:attempt in range(1, 20)
    if filereadable(l:pid_file)
      let l:pid = trim(get(readfile(l:pid_file), 0, ''))
      let l:candidate_start_time = s:LlamaServerStartTime(l:pid)
      if s:IsTrackedLlamaServer(l:pid, l:candidate_start_time, a:port)
        let l:start_time = l:candidate_start_time
        break
      endif
    endif
    sleep 100m
  endfor
  call delete(l:pid_file)

  if !s:IsTrackedLlamaServer(l:pid, l:start_time, a:port)
    echohl ErrorMsg
    echom 'Could not verify the launched llama-server PID on port ' . a:port
    echohl None
    return 0
  endif

  if writefile([l:pid . "\t" . l:start_time . "\t" . a:port], s:llama_pid_file, 'a') != 0
    let l:kill_output = system('kill -TERM ' . l:pid)
    echohl ErrorMsg
    echom 'Could not persist llama-server PID ' . l:pid . ' to ' . s:llama_pid_file
    if v:shell_error != 0
      echom 'Could not stop the untracked llama-server PID ' . l:pid . ': ' . l:kill_output
    endif
    echohl None
    return 0
  endif
  return 1
endfunction

function! KillLlamaServers() abort
  if !filereadable(s:llama_pid_file)
    if getftype(s:llama_pid_file) ==# ''
      return 1
    endif
    echohl ErrorMsg
    echom 'Cannot read llama-server PID file: ' . s:llama_pid_file
    echohl None
    return 0
  endif

  let l:remaining = []
  let l:ok = 1
  for l:entry in readfile(s:llama_pid_file)
    let l:fields = split(l:entry, "\t", 1)
    if len(l:fields) != 3
          \ || l:fields[0] !~# '^[1-9][0-9]*$'
          \ || l:fields[1] !~# '^[1-9][0-9]*$'
          \ || index(['8012', '8013', '8014'], l:fields[2]) < 0
      continue
    endif

    let l:pid = l:fields[0]
    let l:start_time = l:fields[1]
    if !s:IsTrackedLlamaServer(l:pid, l:start_time, l:fields[2])
      continue
    endif

    let l:kill_output = system('kill -KILL ' . l:pid)
    if v:shell_error != 0
      if s:IsTrackedLlamaServer(l:pid, l:start_time, l:fields[2])
        let l:ok = 0
        call add(l:remaining, l:entry)
        echohl ErrorMsg
        echom 'Failed to terminate tracked llama-server PID ' . l:pid . ': ' . l:kill_output
        echohl None
      endif
      continue
    endif

    let l:stopped = 0
    for l:attempt in range(1, 20)
      sleep 100m
      if !s:IsTrackedLlamaServer(l:pid, l:start_time, l:fields[2])
        let l:stopped = 1
        break
      endif
    endfor
    if !l:stopped
      let l:ok = 0
      call add(l:remaining, l:entry)
      echohl ErrorMsg
      echom 'Tracked llama-server PID ' . l:pid . ' did not stop'
      echohl None
    endif
  endfor

  if writefile(l:remaining, s:llama_pid_file) != 0
    echohl ErrorMsg
    echom 'Could not update llama-server PID file: ' . s:llama_pid_file
    echohl None
    return 0
  endif
  return l:ok
endfunction


" Llama.vim AI Assistant
function! s:Load_Llama_plugin()
  if exists('g:llama_loaded')
    return
  endif
  
  " Start llama-server if not already running
  call s:Start_llama_server()
  
  " Configure and load plugin
  " let g:llama_config = { 'show_info': 0 }
  packadd llama.vim
  source ~/.vim/vide-llama-config.vim 
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

  " Map enable and disable actions
  inoremap <C-a>e <C-o>:AIEnable<CR>
  inoremap <C-a>d <C-o>:AIDisable<CR>

endfunction

" ============================================================================
" AI Helper Functions
" ============================================================================
function! s:Start_llama_server()
  let l:check = system('pgrep -a llama-server | grep 8012')
  if empty(l:check)
    " No server running, prompt for model selection
    let l:model_choice = confirm('Select Llama model:', 
          \ "&Qwen2.5-Coder-0.5B\nQ&wen2.5-Coder-3B (default)\n&Custom command", 
          \ 1)
    if l:model_choice == 0
      echom "llama-server startup cancelled."
      return
    elseif l:model_choice == 1
      " Qwen2.5-Coder-0.5B
      let l:llama_args = '--port 8012 -c 2048 --hf-repo ggml-org/Qwen2.5-Coder-0.5B-Q8_0-GGUF --hf-file qwen2.5-coder-0.5b-q8_0.gguf'
    elseif l:model_choice == 2
      " Qwen2.5-Coder-3B default
      let l:llama_args = '--port 8012 -c 2048 --fim-qwen-3b-default'
    elseif l:model_choice == 3
      " Custom command
      let l:llama_args = input('Enter llama-server command: llama-server ', '--port 8012 -c 8192 --fim-qwen-1.5b-default')
      if empty(l:llama_args)
        echom "llama-server startup cancelled."
        return
      endif
    endif

    " Launch llama-server
    echom "Starting llama-server."
    call s:StartTrackedLlamaServer('llamaServer', '8012', l:llama_args)
  endif

  " Launch embeddings server
  let l:check = system('pgrep -a llama-server | grep 8013')
  if empty(l:check)
    echom "Starting Embeddings llama-server."
    let l:embeddings_args = "-hf Snowflake/snowflake-arctic-embed-m-v1.5:Q8_0 --embeddings --host 127.0.0.1 --port 8013 -c 2048 -ngl auto"
    call s:StartTrackedLlamaServer('llamaServerEmbeddings', '8013', l:embeddings_args)
  endif
  
  " Launch instructions server
  let l:check = system('pgrep -a llama-server | grep 8014')
  if empty(l:check)
    echom "Starting Instruct llama-server."
    let l:instruct_args = "-hf Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q5_K_M --host 127.0.0.1 --port 8014 -c 8192 -ngl auto --cont-batching"
    call s:StartTrackedLlamaServer('llamaServerInstruct', '8014', l:instruct_args)
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
" Status Line AI Display
" ============================================================================
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
