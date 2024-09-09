#!/usr/bin/env bash

if [[ "${ADD_PATH:-}" ]]; then
  export PATH=$ADD_PATH:$PATH
fi

shopt -s extglob dotglob globstar huponexit

complete -r # remove built-in shell completion since it currently has problems

if [[ -e /tmp/prompt_name ]]; then
  prompt_name=$(</tmp/prompt_name)
  prompt_name=${prompt_name%%*( )}
fi

export prompt_name
NL=$'\n'

alias sp='source /etc/profile'
alias ls='ls --color=auto'
alias l='ls --color=auto -l'
alias ll='ls --color=auto -la'
alias rmr='rm -rf'
alias u='builtin cd ..'
alias uu='builtin cd ../..'
alias uuu='builtin cd ../../..'
alias vi=vim
alias vis='vim /etc/profile.d/shell-start-0.sh'

# saves existing dir before changing to the given dir
cd() {
  local target=$1 old=$PWD
  if [[ ! "$target" ]]; then
    target=$HOME
  fi
  target=$(unrealpath "$target") || return 1
  if [[ -f "$target" ]]; then
    vim "$target"
  elif [[ ! -d "$target" ]]; then
    echo "Error: target doesn't exist or is not a folder: $target" >&2
    return 1
  else
    if [[ "$old" == "$target" \
       || "${old%/*}" == "$target" \
       || "$old" == "${target%/*}" \
       || ! -d "$old" \
       ]]; then
      # don't need to record, since the change is small
      :
    else
      pushd $PWD >/dev/null || return 1
      local d=$(dirs)
      if (( ${#d} > 2000 )); then
        # remove bottom of stack so we don't grow too big
        popd -n -0 >/dev/null
      fi
    fi
    builtin cd "$target" || return 1
  fi
  return 0
}

walk_menu() {
  local line key message result remainder
  for line in "${choices[@]}"; do
    key=${line%% *}
    message=${line#$key }
    message=${message%% *}
    echo "$key  $message"
  done
  local input
  read -sp "Where to go? " -n1 input || return 1
  choice=
  for line in "${choices[@]}" "${hidden_choices[@]}"; do
    key=${line%% *}
    message=${line#$key }
    message=${message%% *}
    remainder=${line#$key $message }
    if [[ "$remainder" != "$line" ]]; then
      result=$remainder
    else
      result=$message
    fi
    if [[ $key == $input ]]; then
      choice=$result
      break
    fi
  done
  if [[ "$choice" ]]; then
    echo "$message"
  else
    echo
  fi
}
 
walk_add_dirs() {
  local dirs i d 
  dirs=$(find . -mindepth 1 -maxdepth 1 -type d -not -name ".*" | sort -g) || return 1
  if [[ "$dirs" ]]; then
    i=0
    for d in $dirs; do
      (( i++ ))
      choices+=( "$i ${d##*/} $d" )
    done
  fi
}

walk() {
  local hidden_choices choices choice path
  echo "Press ? for more info or q to quit"
  hidden_choices=(
    "q quit"
    "? help"
    )
  while true; do
    choices=()

    if [[ -d .. ]]; then
      choices+=( ". .." )
    fi

    if [[ $PWD == */.dna/* ]]; then
      path=${PWD%%/.dna/*}
      choices+=( "c cell $path" )
      if [[ $PWD == */up || $PWD == */down ]]; then
        walk_add_dirs || return 1
      else
        if [[ -d trunk_dims ]]; then
          choices+=( "t trunk_dims" )
        fi
        if [[ -d sub_dims ]]; then
          choices+=( "s sub_dims" )
        fi
        if [[ -d props ]]; then
          choices+=( "p props" )
        fi
        if [[ -d up ]]; then
          choices+=( "u up" )
        fi
        if [[ -d down ]]; then
          choices+=( "d down" )
        fi
      fi
    elif [[ $PWD == */.cyto/* ]]; then
      path=${PWD%%/.cyto/*}
      choices+=( "c cell $path" )
      if [[ -d up ]]; then
        choices+=( "u up" )
      fi
      if [[ -d up-chosen ]]; then
        choices+=( "U up-chosen" )
      fi
    else
      if [[ -d .cyto ]]; then
        choices+=( "c .cyto" )
      fi
      if [[ -d .dna ]]; then
        choices+=( "d .dna" )
      fi
      if [[ $PWD == *:* ]]; then
        path=${PWD%%:*}
        path=${path%/*}
        choices+=( "t trunk $path" )
      fi
    fi

    if [[ "$choices" ]]; then
      walk_menu || break
      if [[ "$choice" == help ]]; then
        echo "Press one of the characters in the menu to go to the corrosponding folders, or q to quit."
        # later
        #echo "You can also use / to search for a substring."
      elif [[ "$choice" == quit ]]; then
        break
      elif [[ -d "$choice" ]]; then
        cd "$choice" || return 1
      else
        echo "Invalid selection, try again."
        continue
      fi
      local highlight=$'\033[1;33m' \
        reset=$'\033[0m'
      echo "$highlight$(short_path)$reset"
    else
      echo "Nothing to see here."
      break
    fi

  done
}

back() {
  popd &>/dev/null || { echo "Dir doesn't exist."; popd -n &>/dev/null; }
}

# reverse link
#   rln {from} {to}
# will move the file {from} to {to} and then link {from} to {to}
rln() {
  local from=$1 to=$2
  local to_parent=${to%/*}
  if [[ ! -e $from ]]; then
    echo "$from doesn't exist" >&2
    return 1
  fi
  if [[ ! -d $to_parent ]]; then
    echo "Target folder $to_parent doesn't exist" >&2
    return 1
  fi
  if [[ $to == */ ]]; then
    to=$to${from##*/}
  fi
  if [[ -e $to ]]; then
    echo "Target $to already exists exist" >&2
    return 1
  fi
  mv $from $to || return 1
  ln -s $to $from || return 1
}

# prefix move
# usage: pmv {from} {to_prefix}
# example:
#   pmv 1-some-file 2
# would be equivalent to:
#   mv 1-some-file 2-some-file
pmv() {
  local from=$1 to=$2 postfix to_size
  if [[ ! -e $from ]]; then
    echo "Source doesn't exist: $from" >&2
    return 1
  fi
  to_size=${#to}
  postfix=${from:$to_size}
  to=$to$postfix
  mv "$from" "$to"
}

alias b=back
alias bb='back; back;'
alias bbb='back; back; back;'

alias up='cell update'
alias clean='cell clean'

# git stuff
alias gc='git checkout'
alias gb='git branch -vv'
alias gs='git status -uno'
alias gsu='git status'
alias ga='git add'
alias gcb='git checkout -B'
alias gu='git reset --hard && git clean -df'
alias grm='git reset main'
alias gsc='git clone --depth 1'
alias gp='git pull'
alias gd='git diff'
alias push='git push'
alias gbs='git bisect start'
alias gbg='git bisect good'
alias gbb='git bisect bad'
alias gr='git remote'

log_fatal() {
  echo "$*" >&2
}

# resolves relative paths but does not resolve symlinks
# should run in a subprocess so dir change doesn't affect caller
# normal usage: x=$(unrealpath "$some_path")
unrealpath() {
  local p=$PWD x=$1
  if [[ "$x" != /* ]]; then
    x="$p/$x"
  fi
  realpath -s "$x" || {
    log_fatal "Internal error: could not resolve $x"
    return 1 
    }
  return 0
}

# usage: cat file | hydrate >output
#   will replace bash variables and expressions
hydrate() {
  local to_execute= OIFS=$IFS IFS=$NL
  while read -r line || [ "${line:-}" ]; do
    IFS=$OIFS
    if [[ "$line" =~ ^\$\  ]]; then
      hydrate_execute || return 1
      to_execute="${line#\$ }" 
    elif [[ "$line" =~ ^\>\  ]]; then
      to_execute+="${line#> }" 
    elif [[ "$line" =~ ^\\\  ]]; then
      to_execute+="$NL${line#\\ }" 
    elif [[ "$line" =~ \$ ]]; then
      hydrate_execute || return 1
      line="${line//\"/\\\"}"
      eval "echo \"$line\"" || return 1
    else
      hydrate_execute || return 1
      echo "$line"
    fi
    IFS=$NL
  done
  hydrate_execute || return 1
}

# internal function used by hydrate function
hydrate_execute() {
  if [[ "$to_execute" ]]; then
    eval "$to_execute" || return 1
    to_execute=
  fi
  return 0
}

# usage: echo -e "\n\n blah  \n\n" | trim_newlines
# will trim empty lines from beginning and end of given string
# will leave exactly one trailing newline at the end
trim_nl() {
  local block
  read -r -d '' block
  block=${block##*($NL)}
  block=${block%%*($NL)}
  echo "$block"
}

# returns byte_count which is the count of the bytes in the input string
# not the character count
get_byte_count() {
  local old=$LANG s=$1
  LANG=C
  byte_count=${#s}
  LANG=$old
}

real() {
  cd $(realpath .)
  pwd
}

# this unlinks a linked file by copying what it links to locally
unset localize
localize() {
  for file; do

    local target=$(realpath $file)

    if [[ ! -e "$target" ]]; then
      echo "Target of link $file doesn't exist: $target" >&2
      return 1
    fi

    if [[ "$target" == "$file" ]]; then
      echo "File $file is not a link" >&2
      return 1
    fi

    rm "$file" || return 1
    cp -R -a -p "$target" "$file" || return 1

  done
}

vigr() {
  files=$(grep -D skip -srIl "$@" *);
  vim $files
}

rcp() {
  local shell="ssh";
  if [ "${port:-}" ]; then
      shell="ssh -p $port"
  fi
  RSYNC_RSH="$shell" rsync -a --append --inplace --partial --progress "$@"
}

unset gl
gl() {
  git --no-pager log -n ${lines:-20} --decorate --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s" "$@"
}

unset gB
gB() {
  git --no-pager log -n ${lines:-20} --simplify-by-decoration --all --date-order --decorate --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s" "$@"
}

unset gcm
gcm() {
  local message="$1"; shift
  if [ "$message" ]; then
      git commit -m "$message" "$@" || return 1
  else
      git commit || return 1
  fi
}

unset ifout
ifout() {
  awk 'BEGIN { rc=1 } length($0) > 0 { rc=0; print } END { exit rc }'
}

alias f1='find . -maxdepth 1 -not -path "*/.git*"'
alias f2='find . -maxdepth 2 -not -path "*/.git*"'
alias f3='find . -maxdepth 3 -not -path "*/.git*"'
alias f4='find . -maxdepth 4 -not -path "*/.git*"'

unset f
f() {
  local return_code=0
  if [ "$*" ]; then
    find . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' -name "$@" 2>/dev/null | ifout || return_code=1
  elif [ "${depth:-}" ]; then
    find . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' -maxdepth $depth 2>/dev/null | ifout || return_code=1
  else
    find . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' 2>/dev/null | ifout || return_code=1
  fi

  return $return_code
}

unset fd
fd() {
  local depth=$1; shift
  local return_code=0
  find . -mindepth $depth -maxdepth $depth -name "$@" 2>/dev/null | ifout || return_code=1

  return $return_code
}

unset ff
ff() {
  local i
  for ((i = 1; i < 20; i++)); do
    echo "searching depth $i..."
    fd $i "$@"
    if [ "$?" != 0 ]; then
      echo -e "$MOVE_UP"
    fi
  done
}

unset grepr
grepr() {
  grep -D skip -n -s -r -I "$@" *
}

unset grepri
grepri() {
  grep -D skip -n -s -r -i -I "$@" *
}

alias cutf='cut -d " " -f'
alias short='cut -c -160'
alias short2='cut -c -320'
alias short3='cut -c -640'

set -o vi
set +H
export SHELL="/bin/bash"
export LS_OPTIONS='--color=auto'
export EDITOR=vim

find1() {
  if [[ ! -d "${1:-}" ]]; then
    echo "find1: directory missing: ${1:-}" >&2
    return 1
  fi
  local path=$1; shift
  find -L "$path" -mindepth 1 -maxdepth 1 "$@"
  return 0
}

cd_to_leaf() {
  while true; do
    local members=( $(find1 . -type d -name "*:*" | sort -g) ) || return 1
    if [[ "$members" ]]; then
      cd $members || return 1
    else
      break
    fi
  done
  return 0
}

cd_to_trunk() {
  local d=$PWD last_cell=$PWD
  while [[ $d =~ : ]]; do
    d=${d%/*}
    if [[ -e $d/.dna ]]; then
      last_cell=$d
    fi
    if [[ $d != */* ]]; then
      break
    fi
  done
  if [[ $last_cell != $PWD ]]; then
    cd $last_cell || return 1
  fi
  return 0
}

cd_to_seed() {
  local seed=/seed${PWD#/work}

  while [[ ! -d $seed && ${#seed} -gt 5 ]]; do
    seed=${seed%/*}
  done

  if [[ -d $seed ]]; then
    cd $seed || return 1
  else
    echo "Failed to find seed." >&2
    return 1
  fi
   
  return 0
}

cd_to_work() {
  local work=/work${PWD#/seed}

  while [[ ! -d $work && ${#work} -gt 5 ]]; do
    work=${work%/*}
  done

  if [[ -d $work ]]; then
    cd $work || return 1
  else
    echo "Failed to find work." >&2
    return 1
  fi
   
  return 0
}

leaf() {
  cd_to_leaf
}

trunk() {
  cd_to_trunk
}

seed() {
  cd_to_seed
}

work() {
  cd_to_work
}

plant() {
  cd_to_work
}

unset parse_git_branch
parse_git_branch() {
  local p=$PWD
  while [[ "$p" =~ / ]]; do
    if [ -d $p/.git ]; then
      local r=$(cat $p/.git/HEAD)
      if [[ "$r" =~ refs/heads ]]; then
        echo "$r" | sed -E 's/.*refs\/heads\/(.*)/(\1) /'
      else
        git branch 2>/dev/null | sed -E -e '/^[^*]/d' -e 's/^\* (.*)/\1 /'
      fi
      break
    fi
    p=${p%/*}
  done
}

RED="\[\033[0;31m\]"
LIGHT_RED="\[\033[1;31m\]"
RESET="\[\033[0m\]"
BLUE="\[\033[0;34m\]"
LIGHT_BLUE="\[\033[1;34m\]"
PURPLE="\[\033[0;35m\]"
LIGHT_PURPLE="\[\033[1;35m\]"
CYAN="\[\033[0;36m\]"
GREEN="\[\033[0;32m\]"
LIGHT_GREEN="\[\033[1;32m\]"
YELLOW="\[\033[0;33m\]"
LIGHT_YELLOW="\[\033[1;33m\]"

TAB=$'\t'
NL=$'\n'

get_cell_location_string() {
  local p= close=f

  if [[ $PWD == /work/* ]]; then
    p+="[work"
    close=t
  elif [[ $PWD == /seed/* ]]; then
    p+="[seed"
    close=t
  fi

  if [[ $PWD == */.cyto || $PWD == */.cyto/* ]]; then
    p+=" cyto"
  fi

  if [[ $PWD == */.dna || $PWD == */.dna/* ]]; then
    p+=" dna"
  fi

  local sub_branches=( $(find1 . -name "*:*") ) || return 1
  if [[ $PWD =~ : ]]; then
    if [[ "$sub_branches" ]]; then
      p+=" branch"
    else
      p+=" leaf"
    fi
  elif [[ "$sub_branches" ]]; then
    p+=" trunk"
  fi

  if [[ $PWD == */up/* ]]; then
    p+=" up"
  elif [[ $PWD == */down/* ]]; then
    p+=" down"
  fi

  if [[ $close == t ]]; then
    p+="] "
  fi

  cell_location_string=$p
}

# could be overridden by other components
custom_prompt_status() {
  get_cell_location_string
  echo -n "$cell_location_string "
}

out_exec() {
  local p=( "$@" )
  echo '' "${p[@]}" >&2
  eval "${p[@]}"
}

# moves a file or folder and updates all links pointing to it
relink() {
  local from=$1 to=$2 start_at=${start_at:-$PWD}

  local link target 
  local links=( $(find "$start_at" -mindepth 1 -type l 2>/dev/null) ) || return 1
  for link in "${links[@]}"; do
    target=$(readlink $link)
    if [[ "$target" == "$from" \
       || "$target" == "$from"/* \
       ]]; then

      local sub_path=
      if [[ "$target" == "$from"/* ]]; then
        sub_path=${target#$from}
      fi

      out_exec rm "$link" || return 1
      out_exec ln -s "$to$sub_path" "$link" || return 1
    fi
  done

  if [[ -e "$from" && ! -e "$to" ]]; then
    out_exec mv "$from" "$to" || return 1
  fi

  return 0
}

cell() { 
  command cell "$@"
  local rc=$? p=$PWD
  while [[ ! -d $p ]]; do 
    p=${p%/*}
  done
  builtin cd $p 
  return $rc
}

prompt_error_string() {
  local rc=$?
  (( rc > 0 )) && echo -n "err=$rc "
}

short_path() {
  local p=$PWD
  if [[ "$p" == /*/*/*/* ]]; then
    p=${PWD%/*/*/*}
    p=${PWD#$p/}
  fi
  echo -n "$p"
}

pid_path() {
  local result=$$ parent_pid parent_command current_pid=$$
  while true; do
    if [[ "${MAC:-}" ]]; then
      parent_pid=$(ps -co ppid -p $current_pid | tail +2 | awk '{print $1}') || break
      parent_command='('$(ps -co comm -p $parent_pid | tail +2 | awk '{print $1}')')' || break
    else
      parent_pid=$(awk '{print $4}' /proc/$current_pid/stat) || break
      parent_command=$(awk '{print $2}' /proc/$current_pid/stat) || break
    fi
    if [[ $parent_command != '(bash)' || $parent_pid == 0 || $parent_pid == 1 ]]; then
      break
    fi
    result="$parent_pid/$result"
    current_pid=$parent_pid
  done
  echo "pid=$result "
}

big_prompt() {
  if [ ! "$BASH" ]; then
    return 0
  fi

  export PS1="
| $LIGHT_GREEN\$prompt_name $LIGHT_BLUE\d \A $RED\$(prompt_error_string)$YELLOW\$(pid_path)$CYAN\$(custom_prompt_status 2>/dev/null)$RESET
| $LIGHT_YELLOW\$(short_path) $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$RESET\\\$ "
  export PS2='> '
  export PS4='+ '
}

medium_prompt() {
  export PS1="$LIGHT_GREEN\$prompt_name $YELLOW\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$RESET\\\$ "
}

small_prompt() {
  export PS1="$YELLOW\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$RESET\\\$ "
}

big_prompt

