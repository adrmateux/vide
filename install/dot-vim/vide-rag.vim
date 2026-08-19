" ============================================================================
" Vide - Local RAG Module
" ============================================================================
" Query a local knowledge base folder with tools/ai/llama-rag's local_rag.
" Reuses the same embeddings (8013) and instruct (8014) llama-server
" backends already managed by vide-ai.vim for llama.vim FIM completion.

let g:vide_rag_bin = get(g:, 'vide_rag_bin', expand('~/.vim/tools/ai/llama-rag/build/local_rag'))
let g:vide_rag_profile = get(g:, 'vide_rag_profile', 'balanced')
let g:vide_rag_last_folder = get(g:, 'vide_rag_last_folder', getcwd())

" Ask a question against a local knowledge base folder.
" :RagAsk               - prompts for folder and question
" :RagAsk <folder>       - prompts for question only
" :RagAsk <folder> <question>
function! RagAsk(...) abort
  if !executable(g:vide_rag_bin)
    echohl ErrorMsg
    echo 'local_rag not found/executable at ' . g:vide_rag_bin . ' -- build it first (see tools/ai/llama-rag/README.md)'
    echohl None
    return
  endif

  let l:folder = a:0 >= 1 && !empty(a:1) ? a:1 : input('KB folder: ', g:vide_rag_last_folder, 'dir')
  if empty(l:folder)
    echo "\nRagAsk cancelled."
    return
  endif
  let l:folder = fnamemodify(expand(l:folder), ':p')
  if !isdirectory(l:folder)
    echohl ErrorMsg
    echo "\nNot a directory: " . l:folder
    echohl None
    return
  endif
  let g:vide_rag_last_folder = l:folder

  let l:question = a:0 >= 2 && !empty(a:2) ? a:2 : input('Question: ')
  if empty(l:question)
    echo "\nRagAsk cancelled."
    return
  endif

  " Starts embeddings/instruct llama-server if not already running; no-op
  " when they're already up (e.g. llama.vim already loaded this session).
  call LlamaRestart()

  let l:cmd = shellescape(g:vide_rag_bin)
        \ . ' --emb-port 8013 --chat-port 8014 --profile ' . shellescape(g:vide_rag_profile)
        \ . ' ' . shellescape(l:folder) . ' ' . shellescape(l:question)

  " :terminal does its own naive argv splitting on the trailing text rather
  " than handing it to a real shell, so nested shellescape()'d quotes get
  " mangled (e.g. the '\'' sequence). Write the invocation to a small
  " wrapper script instead and give :terminal a single bare path -- no
  " quoting left for it to misparse.
  let l:script = tempname() . '.sh'
  call writefile(['#!/bin/sh', 'cd ' . shellescape(l:folder) . ' || exit 1', l:cmd, 'rm -f -- "$0"'], l:script)
  call setfperm(l:script, 'rwxr-xr-x')

  execute 'botright terminal ' . l:script
endfunction

command! -nargs=0 RagAsk call RagAsk()

nmap <C-m>r :call RagAsk()<CR>
