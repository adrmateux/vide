" Helper functions
function! DeleteInactiveBufs()
    "From tabpagebuflist() help, get a list of all buffers in all tabs
    let tablist = []
    for i in range(tabpagenr('$'))
        call extend(tablist, tabpagebuflist(i + 1))
    endfor

    "Below originally inspired by Hara Krishna Dara and Keith Roberts
    "http://tech.groups.yahoo.com/group/vim/message/56425
    let nWipeouts = 0
    for i in range(1, bufnr('$'))
        if bufexists(i) && !getbufvar(i,"&mod") && index(tablist, i) == -1
        "bufno exists AND isn't modified AND isn't in the list of buffers open in windows and tabs
            silent exec 'bwipeout' i
            let nWipeouts = nWipeouts + 1
        endif
    endfor
    echomsg nWipeouts . ' buffer(s) wiped out'
endfunction
command! Bdi :call DeleteInactiveBufs()


function! GenerateUMLDiagram()
    let l:save_pos = getpos(".")
    
    " Verify if plantuml and eog are installed
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

    let l:start_line = search('@startuml\s*\(\S\+\)', 'c')
    echo l:start_line
    if l:start_line == 0
        echo "No start pattern found."
        return
    endif
    let l:line = getline(l:start_line)

    echo "Start line: " . l:line
    let l:match = matchstr(l:line, '@startuml\s*\zs\S\+')
    echo "The diagram name:" . l:match

    if empty(l:match)
        echo "No matching filename found."
        return
    endif

    let l:end_line = search('@enduml', 'cW')
    if l:end_line == 0
        echo "No end pattern found."
        return
    endif

    " Use /tmp/ directory for temporary files
    let l:tmp_dir = '/tmp/'
    let l:uml_file = l:tmp_dir . l:match . '.uml'
    let l:output_file = l:tmp_dir . l:match

    execute l:start_line . ',' . l:end_line . 'write! ' . l:uml_file

    let l:diag_format = input("Diagram format (png/svg/eps/pdf/vdx/xmi/scxml/html/txt/utxt/latex/latexNP):", "png")
    echo "Diagram format: " . l:diag_format 
    echo "Generating: " . l:output_file . "." . l:diag_format

    let l:cmd = 'plantuml ' . l:uml_file . ' -t' . l:diag_format 
    let l:cmd2 = 'eog ' . l:output_file . "." . l:diag_format 
    let l:cmd3 = 'rm ' . l:uml_file

    silent execute '!' . l:cmd
    if l:diag_format == "txt"
      silent execute 'r!cat ' . l:output_file . ".a" . l:diag_format
    elseif l:diag_format == "utxt"
      silent execute 'r!cat ' . l:output_file . "." . l:diag_format
    else
      silent execute '!' . l:cmd2 ."&"
    endif
    silent execute '!' . l:cmd3 
    redraw!
    
    echohl MoreMsg
    echo "UML diagram saved to: " . l:output_file . "." . l:diag_format
    echohl None
    call setpos('.', l:save_pos)
endfunction

