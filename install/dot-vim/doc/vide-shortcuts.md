# vide - Quick Help
## Auto-Completion
### MUComplete (insert mode)
<tab>           search for autocomplete hints
<s-tab>         Shift tab will do the same as above in reverse order.

### omnicompletion (set omnifunc=ccomplete#Complete,  Start_ide)        
CTRL n                pau pra toda obra
CTRL N                to navigate through the open pop-up
CTRL P                to navigate through
CTRL X CTRL ]         Tags file completion
CTRL X CTRL d         Definition completion
CTRL X CTRL f         Filename completion (based on files in $PWD)
CTRL X CTRL i         Path pattern completion
CTRL X CTRL k         Dictionary completion
CTRL X CTRL l         Whole line completion
CTRL X CTRL n         Keyword local completion
CTRL X CTRL o         Omni completion completion
CTRL X CTRL v         Command line completion

### For vim autocomplete 
see (:vert :help ins-completion)

## Navigating
CTRL W }        open tag under cursor on a preview split
CTRL W z        closes any preview window
"+y             copy selected text to desktop clipboard
CTRL ^          goto next file

### cscope
CTRL \ s        symbol: find all references to the token under cursor
CTRL \ g        global: find global definition(s) of the token under cursor
CTRL \ c        calls:  find all calls to the function name under cursor
CTRL \ t        text:   find all instances of the text under cursor
CTRL \ e        egrep:  egrep search for the word under cursor
CTRL \ f        file:   open the filename under cursor
CTRL \ i        includes: find files that include the filename under cursor
CTRL \ d        called: find functions that function under cursor calls
 
###  ctags
g ]             to navigate to the tag. CTRL ] may crash ("Couldn't get the TranslationUnit").
CTRL [          to navigate to the tag definition
CTRL T          Jump back from the definition.
CTRL W CTRL+]   Open the definition in a horizontal split 
CTRL \          Open the definition in a new tab
Alt ]           Open the definition in a vertical split

### CCTree
CTRL \ <        Get reverse call tree for symbol
CTRL \ >        Get forward call tree for symbol>
CTRL \ =        Increase depth of tree and update
CTRL \ -        Decrease depth of tree and update 
CR              Open symbol in other window
CTRL P          Preview symbol in other window    
CTRL \          Save copy of preview window 
CTRL l          Highlight current call-tree flow
z...            See :help fold    
zM              Fold all
zR              Unfold all
zr              Unfold by level
zc              Fold current 


