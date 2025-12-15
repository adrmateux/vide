
" ------------------------------------------------------------
" Smart FQCN opener for XML attributes like class="com.acme.Foo"
" - Handles double or single quotes
" - Works even when cursor is inside the quoted value
" - Falls back to Coc symbols search if file not found
" ------------------------------------------------------------

function! s:ExtractFqcnFromXmlAttribute() abort
  " Get the current line and cursor column
  let l:line = getline('.')
  let l:col  = col('.')

  " Strategy:
  " 1) Find the nearest class= attribute on the line.
  " 2) Support both class="..." and class='...'
  " 3) Extract the value between quotes.
  "
  " We search left-to-right for class= and then pick the first occurrence
  " whose quote range contains the cursor, else fallback to the first.
  let l:matches = []
  let l:idx = 0
  while l:idx >= 0
    let l:idx = match(l:line, '\<class\s*=\s*["' . "'" . ']', l:idx)
    if l:idx >= 0
      " Determine the quote char at l:idx + len('class=') + spaces
      " We’ll just inspect the first quote found after class=
      let l:qpos = match(l:line, '["' . "'" . ']', l:idx)
      if l:qpos >= 0
        let l:quote = l:line[l:qpos]
        " Find closing quote
        let l:endq = match(l:line, '\V' . l:quote, l:qpos + 1)
        if l:endq > l:qpos
          " Extract between quotes
          let l:value = l:line[l:qpos + 1 : l:endq - 1]
          call add(l:matches, {'start': l:qpos + 1, 'end': l:endq - 1, 'value': l:value})
        endif
        let l:idx = l:qpos + 1
      else
        break
      endif
    endif
  endwhile

  " If we found no class="…" attributes, fall back to the word under cursor
  if empty(l:matches)
    let l:word = expand('<cword>')
    return l:word
  endif

  " Prefer the match that actually contains the cursor; else take the first.
  for l:m in l:matches
    if l:col - 1 >= l:m.start && l:col - 1 <= l:m.end
      return l:m.value
    endif
  endfor

  return l:matches[0].value
endfunction

function! s:OpenFqcnUnderCursorSmart() abort
  let l:fqcn = s:ExtractFqcnFromXmlAttribute()
  
  " Debug: Show extracted FQCN
  echom 'DEBUG: Extracted FQCN: ' . l:fqcn

  " Validate it looks like a FQCN (a.b.C)
  if l:fqcn !~# '^[A-Za-z_][A-Za-z0-9_]*\(\.[A-Za-z_][A-Za-z0-9_]*\)\+$'
    echohl WarningMsg
    echom 'No valid fully-qualified class name found near cursor.'
    echohl None
    return
  endif

  " Convert to a src path; adjust this to your project layout if needed
  let l:rel = substitute(l:fqcn, '\.', '/', 'g') . '.java'
  let l:path_candidates = [
        \ 'src/main/java/' . l:rel,
        \ 'src/test/java/' . l:rel,
        \ l:rel
        \ ]

  " Debug: Show all candidate paths
  echom 'DEBUG: Trying paths:'
  for l:p in l:path_candidates
    echom 'DEBUG:   - ' . l:p . ' (readable: ' . filereadable(l:p) . ')'
    if filereadable(l:p)
      echom 'DEBUG: Opening file: ' . l:p
      execute 'edit ' . l:p
      return
    endif
  endfor

  " Fallback: use coc-java's workspace symbol search if available
  " (Lets you jump even across modules/gradle source sets/etc.)
  if exists(':CocList')
    " Pre-fill the search box with the short class name
    let l:short = split(l:fqcn, '\.')[-1]
    execute 'CocList -I symbols ' . l:short
    return
  endif

  echohl WarningMsg
  echom 'Class file not found; tried: ' . join(l:path_candidates, ', ')
  echohl None
endfunction

" Buffer-local mapping for XML:
autocmd FileType xml nnoremap <buffer> ma :call <SID>OpenFqcnUnderCursorSmart()<CR>
" Optional alternative mappings:
" autocmd FileType xml nnoremap <buffer> <CR> :call <SID>OpenFqcnUnderCursorSmart()<CR>
" autocmd FileType xml nnoremap <buffer> <leader>j :call <SID>OpenFqcnUnderCursorSmart()<CR>
