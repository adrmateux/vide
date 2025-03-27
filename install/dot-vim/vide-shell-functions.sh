#!/bin/bash 
# NOTE: CTRL-\_CTRL-N - is used in vim to go from any mode to normal mode.

# Fire up a new server according to the argument supplied
vs(){
  local RC=$(ps aux | grep "[v]i.*--servername $VI_SERVER")
  if [ -z "$RC" ]; then
    local NEW_TAB='-c ":echo \"Loading VIDE DBs ...\""'
    if [ -n "$1" ]; then
      if [ "$1" = "debug" ]; then
        printf "Debug mode.\n"
        DEBUG="-V9"
      else
        NEW_TAB="-c :tabnew $*"
      fi
      echo "Command: $NEW_TAB"
    fi
    if [ "$VI_SERVER" = "vide" ]; then
      # vide is the c/c++/any language editor. The path bellow will be used by _vsfilefind/_vstags/...
      if [ -e "./tags" -a -e "./cscope.files" ]; then
        pwd > ~/.config/vs-working-dir.txt
      else
        printf "\n\nWARNING: No tags or cscope.files found!\n\n"
      fi
    fi
    vim $DEBUG --servername $VI_SERVER -c "source ~/.vim/viderc.vim" -c ":view ~/.vim/doc/vide.md" $NEW_TAB -c ":echo \"Loading VIDE DBs ...\"" -c ":call Start_ide()"
  else
    printf "Vim server (VI_SERVER=$VI_SERVER) already running!"
  fi
}

vss(){  
  vim -c "source ~/.vim/viderc.vim" -c ":call Netrw_server()" .
}

vso(){
  local FILENAME=${1%%:*}
  local TMP=${1##$FILENAME:}
  local LINENUMBER=${TMP%%:*}
  if [ "$FILENAME" = "$LINENUMBER" ]; then
    LINENUMBER=0
  fi
  local TEMP_FILENAME=$(realpath $FILENAME)
  printf "Opening file: $TEMP_FILENAME \n"
  vim --servername $VI_SERVER --remote-send '<C-\><C-N>:tabnew'"$TEMP_FILENAME"'<CR>'
  vim --servername $VI_SERVER --remote-send '<C-\><C-N>:tabmove 0<CR>'
  RV=$(declare -i NUMBER=$LINENUMBER 2>&1)
  if [ -z "$RV" ]; then
    printf "Go to line number: $LINENUMBER\n"
    vim --servername $VI_SERVER --remote-send ":$LINENUMBER<CR>"
  else
    # printf "REMEMBER: Use filename:linumber to go to desired line.\n"
    :
  fi
}

_vsex(){
  # echo "vsex execute vim command: $*"
  vim --servername $VI_SERVER --remote-send "$*"
}

_vsfilefind(){
  local FILE_AND_LINE=${1##*@}
  FILELINE=${FILE_AND_LINE##*:}
  local COMPLETEFILENAME=${FILE_AND_LINE%%:*}
  local FILENAME=${COMPLETEFILENAME##*/}
  local FILEPATH=${COMPLETEFILENAME%%/*}
  local FUNCTION_NAME=${1%%@*}
  echo -e "Filename $FILENAME, line $FILELINE and function name $FUNCTION_NAME - filepath: $FILEPATH\n"
  FOUND_FILES=($(find $(cat ~/.config/vs-working-dir.txt) -path "*$FILEPATH*" -name "$FILENAME" ))
  # echo -e "Found files: ${FOUND_FILES[@]}\n"
}  

_vstags(){
  declare -a FOUND_FILES
  _vsfilefind $1
  declare -i COUNT_FILES=${#FOUND_FILES[@]}
  declare -i LINE=0
  
  if [ $COUNT_FILES -gt 1 ];then
    for f in ${FOUND_FILES[@]}
    do
      let LINE=$LINE+1
      echo -e "$LINE: $f\n"
    done
    read -p "Open file (>=$COUNT_FILES):" SELECTION 
    let SELECTION=$SELECTION-1
    vso ${FOUND_FILES[$SELECTION]}
    # Go to line
    vim --servername $VI_SERVER --remote-send ":$FILELINE<CR>"
  elif [ $COUNT_FILES -eq 1 ];then
    vso $FOUND_FILES
    vim --servername $VI_SERVER --remote-send ":$FILELINE<CR>"
  else
    echo "Couldn't locate any file that corresponds to the tag: $1"
  fi
}  

# The editor aliases
alias vso1="VI_SERVER=editor vso"
alias vs1="VI_SERVER=editor vs"
alias vss1="VI_SERVER=editor vss"
alias vsx1="VI_SERVER=editor vsx"
alias vsp1="VI_SERVER=editor vsp"

# The vim server execute any commands for the default VI_SERVER and for the editor
alias 0.="vsx"
alias 1.="VI_SERVER=editor vsx"
