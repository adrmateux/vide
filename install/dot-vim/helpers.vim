" ============================================================================
" Vide Helper Functions
" ============================================================================
" Utility functions for buffer management, diagram generation, and more

" ============================================================================
" Buffer Management
" ============================================================================

" Delete all inactive buffers (not open in any window or tab)
" Inspired by Hara Krishna Dara and Keith Roberts
" Source: http://tech.groups.yahoo.com/group/vim/message/56425
function! DeleteInactiveBufs()
    " Get list of all buffers currently visible in tabs
    let l:tablist = []
    for i in range(tabpagenr('$'))
        call extend(l:tablist, tabpagebuflist(i + 1))
    endfor

    " Close buffers that are not visible and not modified
    let l:nWipeouts = 0
    for i in range(1, bufnr('$'))
        if bufexists(i) && !getbufvar(i, "&mod") && index(l:tablist, i) == -1
            " Buffer exists AND isn't modified AND isn't in any window/tab
            silent exec 'bwipeout' i
            let l:nWipeouts = l:nWipeouts + 1
        endif
    endfor
    
    echomsg l:nWipeouts . ' buffer(s) wiped out'
endfunction

command! Bdi :call DeleteInactiveBufs()

" ============================================================================
" UML Diagram Generation
" ============================================================================

" Generate UML diagrams using PlantUML
" Searches for @startuml...@enduml blocks and generates diagrams
" Requires: plantuml and eog (Eye of GNOME image viewer)
function! GenerateUMLDiagram()
    let l:save_pos = getpos(".")
    
    " Verify required tools are installed
    if !s:Check_diagram_prerequisites()
        return
    endif
    
    " Find and extract diagram information
    let l:diagram_info = s:Find_UML_diagram()
    if empty(l:diagram_info)
        return
    endif
    
    " Generate the diagram
    call s:Generate_diagram(l:diagram_info)
    
    call setpos('.', l:save_pos)
endfunction

" Check if required tools are available
function! s:Check_diagram_prerequisites()
    if !executable('plantuml')
        echohl ErrorMsg
        echo "Error: plantuml is not installed or not in PATH"
        echohl None
        return 0
    endif
    if !executable('eog')
        echohl ErrorMsg
        echo "Error: eog is not installed or not in PATH"
        echohl None
        return 0
    endif
    return 1
endfunction

" Find UML diagram boundaries and extract diagram name
function! s:Find_UML_diagram()
    " Search for @startuml (with or without name)
    let l:start_line = search('@startuml', 'c')
    
    if l:start_line == 0
        echohl WarningMsg
        echo "No @startuml pattern found in current buffer"
        echohl None
        return {}
    endif
    
    " Search for @enduml
    let l:end_line = search('@enduml', 'cW')
    if l:end_line == 0
        echohl WarningMsg
        echo "No @enduml pattern found"
        echohl None
        return {}
    endif
    
    " Look for 'title' keyword between start and end
    let l:diagram_name = ''
    for l:line_num in range(l:start_line, l:end_line)
        let l:line = getline(l:line_num)
        let l:title_match = matchstr(l:line, '^\s*title\s\+\zs.\+')
        if !empty(l:title_match)
            " Clean up the title to make it a valid filename
            let l:diagram_name = substitute(l:title_match, '[^a-zA-Z0-9_-]', '_', 'g')
            break
        endif
    endfor
    
    " If no title found, generate random filename
    if empty(l:diagram_name)
        let l:diagram_name = 'uml_diagram_' . strftime('%Y%m%d_%H%M%S')
        echohl WarningMsg
        echo "No 'title' found, using generated name: " . l:diagram_name
        echohl None
    endif
    
    return {
        \ 'name': l:diagram_name,
        \ 'start_line': l:start_line,
        \ 'end_line': l:end_line
        \ }
endfunction

" Generate diagram from extracted information
function! s:Generate_diagram(diagram_info)
    let l:tmp_dir = '/tmp/'
    let l:diagram_name = a:diagram_info.name
    let l:uml_file = l:tmp_dir . l:diagram_name . '.uml'
    let l:output_file = l:tmp_dir . l:diagram_name
    
    " Write diagram content to temporary file
    execute a:diagram_info.start_line . ',' . a:diagram_info.end_line . 'write! ' . l:uml_file
    
    " Get desired output format
    let l:format = input("Diagram format (png/svg/eps/pdf/txt/utxt): ", "png")
    
    if !s:Is_valid_format(l:format)
        echohl ErrorMsg
        echo "Invalid format: " . l:format
        echohl None
        call delete(l:uml_file)
        return
    endif
    
    echo "\nGenerating: " . l:output_file . "." . l:format
    
    " Generate diagram with PlantUML
    let l:cmd = 'plantuml ' . shellescape(l:uml_file) . ' -t' . l:format . ' -o ' . shellescape(l:tmp_dir)
    silent execute '!' . l:cmd
    
    " Handle output based on format
    if l:format == "txt" || l:format == "utxt"
        " Insert text diagram into buffer
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
    echo "UML diagram saved to: " . l:output_file . "." . l:format
    echohl None
endfunction

" Validate diagram format
function! s:Is_valid_format(format)
    let l:valid_formats = ['png', 'svg', 'eps', 'pdf', 'vdx', 'xmi', 'scxml', 'html', 'txt', 'utxt', 'latex', 'latexNP']
    return index(l:valid_formats, a:format) != -1
endfunction

" ============================================================================
" Commands
" ============================================================================
command! UMLDiagram :call GenerateUMLDiagram()
