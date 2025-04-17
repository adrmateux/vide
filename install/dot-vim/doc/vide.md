# vide 0.1.1
## vscli - command line vs helpers to use when vs and vss are already open.
vs/vs1   <filename> - Opens new $VI_SERVER and a filename from the cli, if no filename is chosen, opens vide.md (this) file.
vso/vso1 <filename> - Open file from the command line on the open $VI_SERVER
vsx/vsx1 <command>  - Execute command on vim server from the cli (Wdb, bd, tabnew, ... )
vss/vss1            - vs file explorer
vsp/vsp1 [<filename>] - Open <filename> in $VI_SERVER and let the user type vi commands. To quit it press "q" followed by enter.

## Top 100  shortcuts/command
-------------------------------------------------------------------------------
| Com./Shor. | Description            | Com./Shor. | Description              |
-------------------------------------------------------------------------------
|:Wbd        | write and close buff   |:h digraph  | show special char's list |
-------------------------------------------------------------------------------
|:.w !!      | execute line in shell  |:.w !bash   | execute line in shell    |
-------------------------------------------------------------------------------
|:g/text:    | create filtered view   |:verb map   | debug key equence        |
-------------------------------------------------------------------------------
| yy:@"      |exec current line on ex |<C-m>o      | mouse toggle on/off      |
-------------------------------------------------------------------------------
| kk/ko      |vss open/close tab on vs|<C-w>{<C-W>z| open/close prev.wind.tag |
-------------------------------------------------------------------------------
| <C-m>z     |generate uml diagram    | <C-i>s     | Copilot suggest          |
-------------------------------------------------------------------------------
| <C-i>n     | Copilot next sugestion | <C-i>w     | Copilot accept word      |
-------------------------------------------------------------------------------
| <C-i>d     |Copilot dismiss suggest |            |                          |
-------------------------------------------------------------------------------

## Auto-complete
### mu-complete
In order to use mu-complete type:
```
:packadd vim-mucomplete
```

## Installation
### Pre-reqs
* node.js, if you are going to use coc
### Installing
git clone git@github.com:adrmateux/vide.git
cd vide
git submodule init
git submodule update


## Workflow
### Startup
1. If no tags DB, go to the root directory from which you are going to work, then generate tags and cscope.out db files:
'''
sah-create_tags_db.sH
create_clang_complete
or,
create_tags_db.sh #For non sah projects
create_clang_complete
'''
These commands will create the ".tags.db" folder.
2. Start vide on the directory you created the ".tags.db", using the "vs" scripts from /home/sah0731/.myfuncs:
'''
vs [<filename>]
'''
3. On another window open the vi "server" 
'''
vss .
'''
4. In case your file will not have an extension, you can set the syntax anyway by:
:set filetype=bash

### Compilation
It is based on:
set makeprg=/home/sah0731/bin/compile.sh
, e.g.:
:set makeprg=/home/sah0731/workspace/kb/scripts/compile.sh
:cd ./wlan-manager-master_v2.21.4/src
:make wlan-manager

### Refactoring
#### bufdo
First use vimgrem to find the files to change. Go one by one with :cnext and then:
:bufdo %s/pattern/replace/ge | update

bufdo 	Apply the following commands to all buffers.
%s 	Search and replace all lines in the buffer.
pattern 	Search pattern.
replace 	Replacement text.
g 	Change all occurrences in each line (global).
e 	No error if the pattern is not found.
| 	Separator between commands.
update 	Save (write file only if changes were made).

#### args - inconvenient buffer list full of files
Suppose all *.cpp and *.h files in the current directory need to be changed (not subdirectories). One approach is to use the argument list (arglist):

:arg *.cpp 	All *.cpp files in current directory.
:argadd *.h 	And all *.h files.
:arg 	Optional: Display the current arglist.
:argdo %s/pattern/replace/ge | update 	Search and replace in all files in arglist.

A similar procedure can perform the same operation on all wanted files in the current directory, and in all subdirectories (or in any specified tree of directories):
:arg **/*.cpp 	All *.cpp files in and below current directory.
:argadd **/*.h 	And all *.h files.
... 	As above, use :arg to list files, or :argdo to change. 

### Programming

#### Creating UML diagrams
You can create UML diagrams with help from plantuml

As an example you can put the cursor just before the @startuml bellow
```
@startuml diag_name
wlm -> wld : s_initiateWPS
wld -> wld : hello_3
@enduml
```
, and execute:
```
:/@startuml/,/@enduml/w! .tmp.uml.txt|!reset;plantuml .tmp.uml.txt; rm .tmp.uml.txt;eog diag_name.png
```


#### Shortcuts
CTRL W } - open tag under cursor on a preview split
CTRL W z - closes any preview window

## Extra stuff
### Debuging with vide - Termdebug
First, execute ~/bin/sah-coredump-analysis.sh.
Then, download files and extract them accordingly.

#### Where to change the debugger in iderc.vim 
:let g:termdebugger='gdb-multiarch'

#### Shortcuts
CTRL w N        - Starts normal mode in order to move around on the freezed terminal (!!!! press i to insert mode)

#### Running gdb
On vin ex cli:
```
:cd <ticket-path>/rootfs
```
, edit gdbinit so as to update ticket path:
```
:tabnew gdbinit
:Termdebug
```
, then when on gdb cli:
```
source gdbinit
```
, then open the backtrace:
```
bt
```
, and go to the frame of interest, e.g.:
```
frame 2
```
, and magically vim will open another split with the souce code of interest. If it doesn't happen verify your gdbinit file.

NOTE: If for some reason the code is not automagically open, there could be a difference on the path. Most cases it shall be related to the version of the component, e.g.:
```
(gdb) info source
Current source file is policy/bs_policy_steer_score.c
Compilation directory is /home/sahbot/workspace/build/buildsystem/build_dir/target-arm-buildroot-linux-gnueabi_glibc/ssw-master_v7.44.46/src
Located in /home/sah0731/workspace/p12/full-featured-prplwrt_safran_full-amx-2203-image/buildsystem/build_dir/target-arm-buildroot-linux-gnueabi_glibc/ssw-ma
ster_v7.44.46/src/policy/bs_policy_steer_score.c   
```
, which does not correspond to the one in my build: ssw-master_v7.44.63

If you have :set mouse=a, then just go to the source code that poped out in the screen and hover it over the variables. You'll be able to see their values at the moment of the frame.

#### Tricks
In order to have the ":Winbar", type "set mouse=a". Then you can see all symbols by hovering the mousei over the variables. There is also the popup menu with the "Set breakpoint", "Clear breakpoint" and "Evaluate" options.

Type "frame N" to go to the desired frame and respective code. An extra window will be open showing where the code is.
Hovering over variables will show ballons with the values.

##### log analysis
When trying to find out what happend on a log file arroud a certain time:
:g/Jul 30 09:4[567]
, this will show around 45 and 47 minutes.

#### example gdbinit (on gdb cli: "source <path>/gdbinit_file")
target exec /home/sah0731/workspace/p12/tmp/SSW-8272/sah-pairing/rootfs/bin/pcb_app
set sysroot /home/sah0731/workspace/p12/tmp/SSW-8272/sah-pairing/rootfs
core-file /home/sah0731/workspace/p12/tmp/SSW-8272/sah-pairing/dump/2/core 
add-auto-load-safe-path /opt/softathome/toolchain/bcm9xxx-arm_softfp-linux-4.19-gcc-10.3-glibc2.32/arm-buildroot-linux-gnueabi/sysroot/lib/
set libthread-db-search-path /opt/softathome/toolchain/bcm9xxx-arm_softfp-linux-4.19-gcc-10.3-glibc2.32/arm-buildroot-linux-gnueabi/sysroot/lib/
set substitute-path /home/sahbot/workspace/build/ /home/sah0731/workspace/p12/full-featured-prplwrt_safran_full-amx-2203-image/ 

#### gdb remote session
Copy an unstriped executable to the remote machine. Check if the file is unstrippedf like:
find . -name wlan-manager.so -exec file {} \;

Stop the firewall like:
/etc/init.d/tr181-firewall stop
, or like:
'''
Firewall.Service.+
Firewall.Service.new-service.DestPort=666
Firewall.Service.new-service.Interface="Device.IP.Interface.3." # Lan interface of WNC-board
Firewall.Service.new-service.Protocol=6 # TCP
Firewall.Service.new-service.IPVersion=4
Firewall.Service.new-service.Enable=1
 
The newly created service should now be enabled, check DM to be sure

Firewall.Service.42.Status="Enabled"
'''

On the remote machine:
gdbserver --attach :5555 $(ps x | grep "[w]lan"| awk '{print $1}')

On the local gdb:
target remote 192.168.1.1:5555

#### Useful shortcuts for Termdebug and Terminal
CTRL W CTRL F - Open file in a new windowi (see :help gf)
gf            - Open file on the same window
CTRL W SHFT n - Enable terminal scroll
SHFT i        - Return to normal mode

### END OF WORKFLOW SECTION


## EXTRA STUFF
## copy paste
" + y         - copy to the clipboard register ("+p  type all the simbols)

My current WORKING!!!! configuration, on the:
:set clipboard 
clipboard=autoselect,exclude \|linux

To see the registers:
:reg


### Filter netrw so only desired extensions are visible
```
:let g:netrw_list_hide='.*\.d$,.*\.o$,.*\.swp$'
:let g:netrw_hide = 1
```

### Usefull shortcuts
CTRL l - reload page/buffer

### coc.nvim
#### installing
Run the following command the first time you will use vs with coc.nvim:
```
vim -c "let g:coc_disable_startup_warning = 1" -c "packadd coc.nvim" -c ":call coc#util#install()" -c "helptags coc.nvim/doc/ | q"
```
Next, it will enter vim and a message of npm showing coc was compiled will appear at the screen.

See https://stackoverflow.com/questions/69841916/neovim-coc-nvim-build-inderx-js-not-found-please-install-dependencies-and-com

### Configuration for coc-clangd
In vim:
```
CocInstall coc-clangd
```

See:
https://github.com/clangd/coc-clangd?tab=readme-ov-file


### cscope
#### Creating cscope db
Use the script /home/sah0731/workspace/kb/vide/create_tags_db.sh to generate the the list of files (cscope.files) to be taken in consideration for the cscope db creation. 

NOTE: see annex I at the end to see it.

The generated db is the file cscope.out.
It shall be added to the environment variable CSCOPE_DB, in, e.g.,  ~/.bashrc.

#### Using cscope in vim
The file ~/.vim/plugin/cscope_map.vim shall be present. This file was retrieved from:
https://cscope.sourceforge.net/cscope_maps.vim
, but matters of protection againts information destruction, if you will, you can find it at annex III.

The mappings are described at the file above. Consult it in ANNEX III.

#### Usefull cscope commands for vi
:cscope add {file|dir}  - add cscope.out file or dir where it is.
:cscope show - show the current loaded cscope.out file.
:help cs

### CCTree
CCTree is a tool that is used with cscope.out file in order to produce some usefull graphs.
You can find it in https://github.com/hari-rangarajan/CCTree?tab=readme-ov-file

#### Configuring it
Checkout files from the repo and copy the files:
cctree.vim
CCTree.txt
, to the ~/.vim/plugin directory

#### Using in vim
First you need to tell CCTree where the cscope.out is, so type in vim:
:CCTreeLoadDB /home/sah0731/workspace/vide/scopedb/cscope.out
, you are ready to go.a
NOTE: It may take a while to load all symbols, e.g.:
CCTree: Done loading database. xRef Symbol Count: 11940. Time taken:  11.505224 secs

If you want a call tree, issue:
<CTRL-\><  Get reverse call tree for symbol
<CTRL-\>>  Get forward call tree for symbol>
<CTRL-\>=  Increase depth of tree and update
<CTRL-\>-  Decrease depth of tree and update 

<CR>       Open symbol in other window
<CTRL-P>   Preview symbol in other window    
<CTRL-\>y  Save copy of preview window 
<CTRL-l>   Highlight current call-tree flow
zs         Compress(Fold) call tree view     zs
             (This is useful for viewing long
              call trees which span across
              multiple pages)

### ctags
#### Creating the DB
Go to directory: 
/home/sah0731/workspace/p12/full-featured-prplwrt_safran_full-amx-2203-image/buildsystem/build_dir/target-arm-buildroot-linux-gnueabi_glibc
, and issue the command ctags (the ~/.ctags file shall be present before hand):
ctags
NOTE: issuing command ctags like this will generate a gigantic tags file (aprox.1.5GB). Issue:
ctags -L ~/workspace/vide/scopedb/cscope.files
, this way you reuse the file created for cscope.

### clang_complete
Pluning installed at pack/completion/start/clang_complete
It used the file .clang_complete
See pack/completion/start/clang_complete/README.md

### Using spelling correction <C-u>
In order to use the aspell for english/french/spanish:
```
:let $LC_MESSAGES = "fr"
:let $LC_MESSAGES = "es"
:let $LC_MESSAGES = ""
:let $LC_MESSAGES = "pt_BR"
```

### END OF EXTRA STUFF SECTION


## TOSEARCH
- How to break down tags file that takes almost 16 minutes to be generated?
  Running ctags for every directory will only give the vision on the current dir.

## References
https://kulkarniamit.github.io/whatwhyhow/howto/use-vim-ctags.html
https://cscope.sourceforge.net/large_projects.html
https://www.vim.org/scripts/script.php?script_id=2368
https://github.com/hari-rangarajan/CCTree/blob/master/doc/CCTree.txt
https://stackoverflow.com/questions/563616/vim-and-ctags-tips-and-tricks

## VI embedded dictionaries and autocomplete
Search for vi help
:help ins-completion

# TODO: Manage the following section, but not the annexes
# CHANGES - IMPORTANT!!!!
/usr/share/vim/vim82/autoload/ccomplete.vim - line 213
https://github.com/vim/vim/issues/14927

# Dictionarios
/usr/share/dict/

# VIM Script Development
## Black Magic
### CTRL r =
In insert mode this sequence allow you to execute the content of a function on the buffer
See :help *c_CTRL-R* *c_<C-R>*

# Annexes
## I - cscope.conf
OWRT=/home/sah0731/workspace/p12/full-featured-prplwrt_safran_full-amx-2203-image/buildsystem/build_dir/target-arm-buildroot-linux-gnueabi_glibc

DB_DIR=/home/sah0731/workspace/vide/scopedb
DB_FILE=$DB_DIR/cscope.files

find $OWRT \( -path "*/wlan-manager*/*" -o \
	      -path "*/libswl*/*" -o \
	      -path "*/libamx*/*" \) \
	      -name "*.[chxsS]"  -print > $DB_FILE

cd $DB_DIR

cscope -b -q -k

cd -

## II - ~/.ctags
### NOTE:What follows is my current ctags file. For openwrt project it produces on build_dir/target-arm-... a 1.5GB file.
### NOTE: It doesn't seems to afect vim's performance.
--recurse=yes
--exclude=.git
--exclude=BUILD
--exclude=.svn
--exclude=*.js
--exclude=vendor/*
--exclude=node_modules/*
--exclude=db/*
--exclude=log/*
--exclude=\*.min.\*
--exclude=\*.swp
--exclude=\*.bak
--exclude=\*.pyc
--exclude=\*.class
--exclude=\*.sln
--exclude=\*.csproj
--exclude=\*.csproj.user
--exclude=\*.cache
--exclude=\*.dll
--exclude=\*.pdb

## III - cscope_maps.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CSCOPE settings for vim           
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" This file contains some boilerplate settings for vim's cscope interface,
" plus some keyboard mappings that I've found useful.
"
" USAGE: 
" -- vim 6:     Stick this file in your ~/.vim/plugin directory (or in a
"               'plugin' directory in some other directory that is in your
"               'runtimepath'.
"
" -- vim 5:     Stick this file somewhere and 'source cscope.vim' it from
"               your ~/.vimrc file (or cut and paste it into your .vimrc).
"
" NOTE: 
" These key maps use multiple keystrokes (2 or 3 keys).  If you find that vim
" keeps timing you out before you can complete them, try changing your timeout
" settings, as explained below.
"
" Happy cscoping,
"
" Jason Duell       jduell@alumni.princeton.edu     2002/3/7
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" This tests to see if vim was configured with the '--enable-cscope' option
" when it was compiled.  If it wasn't, time to recompile vim... 
if has("cscope")

    """"""""""""" Standard cscope/vim boilerplate

    " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
    set cscopetag

    " check cscope for definition of a symbol before checking ctags: set to 1
    " if you want the reverse search order.
    set csto=0

    " add any cscope database in current directory
    if filereadable("cscope.out")
        cs add cscope.out  
    " else add the database pointed to by environment variable 
    elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
    endif

    " show msg when any other cscope db added
    set cscopeverbose  


    """"""""""""" My cscope/vim key mappings
    "
    " The following maps all invoke one of the following cscope search types:
    "
    "   's'   symbol: find all references to the token under cursor
    "   'g'   global: find global definition(s) of the token under cursor
    "   'c'   calls:  find all calls to the function name under cursor
    "   't'   text:   find all instances of the text under cursor
    "   'e'   egrep:  egrep search for the word under cursor
    "   'f'   file:   open the filename under cursor
    "   'i'   includes: find files that include the filename under cursor
    "   'd'   called: find functions that function under cursor calls
    "
    " Below are three sets of the maps: one set that just jumps to your
    " search result, one that splits the existing vim window horizontally and
    " diplays your search result in the new window, and one that does the same
    " thing, but does a vertical split instead (vim 6 only).
    "
    " I've used CTRL-\ and CTRL-@ as the starting keys for these maps, as it's
    " unlikely that you need their default mappings (CTRL-\'s default use is
    " as part of CTRL-\ CTRL-N typemap, which basically just does the same
    " thing as hitting 'escape': CTRL-@ doesn't seem to have any default use).
    " If you don't like using 'CTRL-@' or CTRL-\, , you can change some or all
    " of these maps to use other keys.  One likely candidate is 'CTRL-_'
    " (which also maps to CTRL-/, which is easier to type).  By default it is
    " used to switch between Hebrew and English keyboard mode.
    "
    " All of the maps involving the <cfile> macro use '^<cfile>$': this is so
    " that searches over '#include <time.h>" return only references to
    " 'time.h', and not 'sys/time.h', etc. (by default cscope will return all
    " files that contain 'time.h' as part of their name).


    " To do the first type of search, hit 'CTRL-\', followed by one of the
    " cscope search types above (s,g,c,t,e,f,i,d).  The result of your cscope
    " search will be displayed in the current window.  You can use CTRL-T to
    " go back to where you were before the search.  
    "

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>


    " Using 'CTRL-spacebar' (intepreted as CTRL-@ by vim) then a search type
    " makes the vim window split horizontally, with search result displayed in
    " the new window.
    "
    " (Note: earlier versions of vim may not have the :scs command, but it
    " can be simulated roughly via:
    "    nmap <C-@>s <C-W><C-S> :cs find s <C-R>=expand("<cword>")<CR><CR>

    nmap <C-@>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@>d :scs find d <C-R>=expand("<cword>")<CR><CR>


    " Hitting CTRL-space *twice* before the search type does a vertical 
    " split instead of a horizontal one (vim 6 and up only)
    "
    " (Note: you may wish to put a 'set splitright' in your .vimrc
    " if you prefer the new window on the right instead of the left

    nmap <C-@><C-@>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-@><C-@>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-@><C-@>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nmap <C-@><C-@>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>


    """"""""""""" key map timeouts
    "
    " By default Vim will only wait 1 second for each keystroke in a mapping.
    " You may find that too short with the above typemaps.  If so, you should
    " either turn off mapping timeouts via 'notimeout'.
    "
    "set notimeout 
    "
    " Or, you can keep timeouts, by uncommenting the timeoutlen line below,
    " with your own personal favorite value (in milliseconds):
    "
    "set timeoutlen=4000
    "
    " Either way, since mapping timeout settings by default also set the
    " timeouts for multicharacter 'keys codes' (like <F1>), you should also
    " set ttimeout and ttimeoutlen: otherwise, you will experience strange
    " delays as vim waits for a keystroke after you hit ESC (it will be
    " waiting to see if the ESC is actually part of a key code like <F1>).
    "
    "set ttimeout 
    "
    " personally, I find a tenth of a second to work well for key code
    " timeouts. If you experience problems and have a slow terminal or network
    " connection, set it higher.  If you don't set ttimeoutlen, the value for
    " timeoutlent (default: 1000 = 1 second, which is sluggish) is used.
    "
    "set ttimeoutlen=100

endif


## III - Interesting chars
To insert unicode character in vim, use CTRL V u <enter unicode>, i.e., to obtain:
 
, press CTRL B ue0b0
 
