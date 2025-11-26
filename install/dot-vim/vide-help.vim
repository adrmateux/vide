" ============================================================================
" Vide - Help Popup Module
" ============================================================================
" Keyboard shortcuts help popup for Vide (Vim Integrated Development Environment)
" Provides a popup window with all available keyboard shortcuts

" ============================================================================
" Shortcuts Help Popup
" ============================================================================
function! ShowShortcutsPopup()
  let l:shortcuts = [
        \ '╔════════════════════════════════════════════════════════════════╗',
        \ '║              VIDE - Keyboard Shortcuts Reference               ║',
        \ '╠════════════════════════════════════════════════════════════════╣',
        \ '║ GENERAL                                                        ║',
        \ '║   :Wbd          - Write and close buffer                       ║',
        \ '║   :Bdi          - Delete inactive buffers                      ║',
        \ '║   yy:@"         - Execute current line in ex mode              ║',
        \ '║   <C-m>o        - Toggle mouse on/off                          ║',
        \ '║   kk/ko         - Open/close tab on VS server                  ║',
        \ '║   <C-w>{/<C-w>z - Open/close preview window                    ║',
        \ '║                                                                ║',
        \ '║ AI ASSISTANTS                                                  ║',
        \ '║   :AIChange     - Change AI assistant for buffer               ║',
        \ '║   :AIEnable     - Enable AI in current buffer                  ║',
        \ '║   :AIDisable    - Disable AI in current buffer                 ║',
        \ '║   <C-j>         - Accept Copilot/Llama suggestion              ║',
        \ '║   <C-i>n        - Copilot next suggestion                      ║',
        \ '║   <C-i>p        - Copilot previous suggestion                  ║',
        \ '║   <C-i>d        - Copilot dismiss suggestion                   ║',
        \ '║   <C-i>s        - Copilot suggest                              ║',
        \ '║   <C-i>w        - Copilot accept word                          ║',
        \ '║                                                                ║',
        \ '║ CODE NAVIGATION                                                ║',
        \ '║   <C-\>         - Jump to tag in new tab                       ║',
        \ '║   <A-]>         - Jump to tag in vertical split                ║',
        \ '║   <C-F10>       - Reload tags database                         ║',
        \ '║   <C-F11>       - Reload CCTree database                       ║',
        \ '║                                                                ║',
        \ '║ COMPLETION                                                     ║',
        \ '║   <C-y>         - Accept completion (coc.nvim)                 ║',
        \ '║   \\rn           - Rename symbol (Coc)                         ║',
        \ '║                                                                ║',
        \ '║ DIAGRAMS & TOOLS                                               ║',
        \ '║   <C-m>z        - Generate PlantUML diagram                    ║',
        \ '║   :UMLDiagram   - Generate PlantUML diagram (command)          ║',
        \ '║                                                                ║',
        \ '║ CODE EXECUTION (Visual mode)                                   ║',
        \ '║   \p            - Execute selected as Python                   ║',
        \ '║   \c            - Execute selected as C++                      ║',
        \ '║   \s            - Execute selected as Bash                     ║',
        \ '║   :''<,''>source   - Execute selected vim script                 ║',
        \ '║                                                                ║',
        \ '║ VISUAL MODE                                                    ║',
        \ '║   <C-o>v        - Visual mode while inserting                  ║',
        \ '║   <C-o><C-v>    - Visual block while inserting                 ║',
        \ '║                                                                ║',
        \ '║ DEBUGGING (Termdebug)                                          ║',
        \ '║   :Termdebug    - Start debugging session                      ║',
        \ '║   <C-w>N        - Normal mode in terminal (press i to exit)    ║',
        \ '║                                                                ║',
        \ '║ USEFUL COMMANDS                                                ║',
        \ '║   :.w !!        - Execute current line in shell (sudo)         ║',
        \ '║   :.w !bash     - Execute current line in shell                ║',
        \ '║   :g/text       - Create filtered view                         ║',
        \ '║   :verb map     - Debug key sequence                           ║',
        \ '║   :h digraph    - Show special characters list                 ║',
        \ '║   <C-u>         - Spell check                                  ║',
        \ '╠════════════════════════════════════════════════════════════════╣',
        \ '║ j/k or ↓/↑ to scroll | q or Esc to close | <C-F1> to reopen   ║',
        \ '╚════════════════════════════════════════════════════════════════╝',
        \ ]
  
  " Create popup window with scrolling support
  let l:popup_id = popup_create(l:shortcuts, {
        \ 'title': ' Keyboard Shortcuts ',
        \ 'line': 1,
        \ 'col': (&columns - 70) / 2,
        \ 'minheight': min([len(l:shortcuts), &lines - 3]),
        \ 'maxheight': &lines - 3,
        \ 'minwidth': 70,
        \ 'maxwidth': 70,
        \ 'border': [],
        \ 'padding': [0, 1, 0, 1],
        \ 'scrollbar': 1,
        \ 'wrap': 0,
        \ 'firstline': 1,
        \ 'filter': {winid, key -> s:ShortcutsPopupFilter(winid, key, len(l:shortcuts))},
        \ })
  
  " Store initial scroll position in window variable
  call setwinvar(l:popup_id, 'vide_scroll_pos', 1)
endfunction

" Filter function to handle keyboard input in the popup
function! s:ShortcutsPopupFilter(winid, key, total_lines)
  " Close on q, Esc, x, or Ctrl-c
  if a:key == 'q' || a:key == "\<Esc>" || a:key == 'x' || a:key == "\<C-c>"
    call popup_close(a:winid)
    return 1
  endif
  
  " Debug: show what key was pressed
  if a:key == 'd'
    let l:pos = popup_getpos(a:winid)
    let l:visible = l:pos.lastline - l:pos.firstline + 1
    let l:maxfirst = a:total_lines - l:visible + 1
    echom "firstline=" . l:pos.firstline . " lastline=" . l:pos.lastline . " height=" . l:pos.height . " total=" . a:total_lines . " visible=" . l:visible . " max=" . l:maxfirst
    return 1
  endif

  " Get current scroll position - use actual position, not options
  let l:pos = popup_getpos(a:winid)
  let l:firstline = l:pos.firstline
  
  " Use actual visible content lines, not height (which includes borders)
  let l:visible_lines = l:pos.lastline - l:pos.firstline + 1
  
  " Calculate max firstline (last page position)
  let l:max_firstline = a:total_lines - l:visible_lines + 1
  if l:max_firstline < 1
    let l:max_firstline = 1
  endif
  
  " Scroll down with j, Down arrow, or Space
  if a:key == 'j' || a:key == "\<Down>" || a:key == "\<Space>"
    let l:newline = l:firstline + 1
    echom "Down: firstline=" . l:firstline . " newline=" . l:newline . " max=" . l:max_firstline . " check=" . (l:newline <= l:max_firstline)
    if l:newline <= l:max_firstline
      call popup_setoptions(a:winid, {'firstline': l:newline})
      echom "Called popup_setoptions with firstline=" . l:newline
    endif
    return 1
  endif
  
  " Scroll up with k or Up arrow
  if a:key == 'k' || a:key == "\<Up>"
    let l:newline = l:firstline - 1
    if l:newline >= 1
      call popup_setoptions(a:winid, {'firstline': l:newline})
    endif
    return 1
  endif
  
  " Page down
  if a:key == "\<PageDown>" || a:key == "\<C-d>"
    let l:newline = l:firstline + l:visible_lines - 2
    if l:newline > l:max_firstline
      let l:newline = l:max_firstline
    endif
    if l:newline > l:firstline
      call popup_setoptions(a:winid, {'firstline': l:newline})
    endif
    return 1
  endif
  
  " Page up
  if a:key == "\<PageUp>" || a:key == "\<C-u>"
    let l:newline = l:firstline - l:visible_lines + 2
    if l:newline < 1
      let l:newline = 1
    endif
    if l:newline < l:firstline
      call popup_setoptions(a:winid, {'firstline': l:newline})
    endif
    return 1
  endif
  
  " Go to top with g
  if a:key == 'g'
    call popup_setoptions(a:winid, {'firstline': 1})
    return 1
  endif
  
  " Go to bottom with G
  if a:key == 'G'
    call popup_setoptions(a:winid, {'firstline': l:max_firstline})
    return 1
  endif
  
  " Consume all other keys to prevent them from affecting the buffer
  return 1
endfunction
