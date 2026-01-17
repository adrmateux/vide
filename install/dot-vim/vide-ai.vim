" ============================================================================
" Vide - AI Assistants Module
" ============================================================================
" AI assistant functionality for Vide (Vim Integrated Development Environment)
" Provides per-buffer AI control for Copilot and Llama.vim

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

  " Map enable and disable actions
  inoremap <C-a>e <C-o>:AIEnable<CR>
  inoremap <C-a>d <C-o>:AIDisable<CR>

endfunction

" ============================================================================
" AI Helper Functions
" ============================================================================
function! s:Start_llama_server()
  let l:check = system('pgrep -x llama-server')
  if empty(l:check)
    " No server running, prompt for model selection
    let l:model_choice = confirm('Select Llama model:', 
          \ "&Qwen2.5-Coder-0.5B (Q8_0)\nQ&wen2.5-Coder-3B (default)\n&Custom command", 
          \ 1)
    
    if l:model_choice == 0
      echom "llama-server startup cancelled."
      return
    elseif l:model_choice == 1
      " Qwen2.5-Coder-0.5B
      call system('screen -dmS llama-server llama-server --hf-repo ggml-org/Qwen2.5-Coder-0.5B-Q8_0-GGUF --hf-file qwen2.5-coder-0.5b-q8_0.gguf -c 2048 --port 8012')
      echom "llama-server started with Qwen2.5-Coder-0.5B."
    elseif l:model_choice == 2
      " Qwen2.5-Coder-3B default
      call system('screen -dmS llama-server llama-server --fim-qwen-3b-default')
      echom "llama-server started with Qwen2.5-Coder-3B."
    elseif l:model_choice == 3
      " Custom command
      let l:custom_cmd = input('Enter llama-server command (without nohup/redirect): ', 'llama-server ')
      if empty(l:custom_cmd)
        echom "llama-server startup cancelled."
        return
      endif
      call system('screen -dmS llama-server ' . l:custom_cmd)
      echom "llama-server started with custom command."
    endif
  else
    echom "llama-server is already running."
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
