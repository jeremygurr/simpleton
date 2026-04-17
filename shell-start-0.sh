#!/usr/bin/env bash

SIMPLETON_LIB=/repo/simpleton/lib
SIMPLETON_REPO=/repo/simpleton
#source $SIMPLETON_LIB/lifted-bash || exit 1
#source $SIMPLETON_LIB/bash-lib || exit 1
#bash_lifted_init
#source $SIMPLETON_LIB/walk-lib || exit 1
source $SIMPLETON_REPO/bin/c2 || exit 1
#lifted_bash_init "$@" || exit 1

COMP_WORDBREAKS=${COMP_WORDBREAKS//:}

if [[ "${ADD_PATH:-}" ]]; then
  export PATH=$ADD_PATH:$PATH
fi

shopt -s extglob dotglob globstar huponexit
set +o histexpand

complete -r # remove built-in shell completion since it currently has problems

if [[ -e /home/prompt_name ]]; then
  prompt_name=$(</home/prompt_name)
  prompt_name=${prompt_name%%*( )}
fi

export prompt_name
NL=$'\n'

#export CHARSET=UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# cell aliases
alias get='yolo=t cell get'
alias update='cell update'
alias upd='cell update'
alias clean='cell clean'
alias clean0='cell clean0'
alias clean1='cell clean1'
alias clean2='cell clean2'
alias clean3='cell clean3'
alias clean-all='cell /work/one-data clean'
alias clean-cache='cell /work/one-data clean kind=derive'
alias status='cell status'
alias reactor='cell reactor'
alias plant='cell plant'
alias mock='cell mock'
alias dim='cell dim'
alias up='cell up'
alias validator='cell validator'
alias ?='cell . ?'
alias ??='cell . ??'
alias safe='cell safe'
alias w=walk
alias f=forge
alias f2=forge_v2

alias sp='source /etc/profile'
alias ls='ls --color=auto'
alias l='ls --color=auto -l'
alias ltr='ls --color=auto -ltr'
alias ll='ls --color=auto -la'
alias rmr='rm -rf'
alias u='builtin cd ..'
alias uu='builtin cd ../..'
alias uuu='builtin cd ../../..'
alias vi=vim
alias vis='vim /etc/profile.d/shell-start-0.sh'
alias dockerv='docker ps --format "{{.Names}} [{{.Label \"artifact_version\" }}] <{{.Label \"ois_version\" }}> ({{.Image}})"'

# used by /etc/profile, this avoids a warning
BB_ASH_VERSION=
ZSH_VERSION= 

pause() {
  read -p "Press enter. "
}

sum1() {
  awk '{ s+=$1 } END { print s }'
}

sum2() {
  awk 'k != "" && k != $1 { print k, t; t=0 } { k=$1; t+=$2 } END { print k, t }'
}

awk1() {
  awk '{ print $1 }'
}

awk2() {
  awk '{ print $2 }'
}

migrate() {
  local name=$1
  if [[ ! -d .dna || $PWD != /work/* ]]; then
    echo "This command must be run within a cell (work not seed)" >&2
    return 1
  fi

  local dna_path=$PWD/.dna
  case "$name" in
    dim)
      local dim_type
      for dim_type in trunk_dims support_dims sub_dims control_props data_props; do
        if [[ -d $dna_path/$dim_type ]]; then
          echo "Converting dims for $dim_type"
          local files
          files=$(find1 $dna_path/$dim_type -printf "%f\n" | sed 's/^\([0-9]\+-\)\?\(.*\)$/\2/' | sort -g)
          echo "$files" >$dna_path/$dim_type.arr || return 1
          rm -fr $dna_path/$dim_type || return 1
        fi
      done
    ;;
    *)
      echo "Unknown migration command: $name" >&2
      return 1
    ;;
  esac
}

get_short_path() {
  local p=$1
  local o=$p
  if [[ "$p" == */*/*/* ]]; then
    p=${p#/work/*/}
    p=${p#/seed/*/}
    o=$p
  fi
  #if [[ "$p" == */*/*/*/* ]]; then
  #  p=${p%*/*/*/*/*}
  #  p=${o#$p/}
  #fi
  short_path=$p
}

find_lib(){
  local c=${1%/.lib}
  while true; do
    c=${c%/*}
    if [[ -d $c/.lib ]]; then
      lib_path=$c/.lib
      break
    fi
    if [[ "$c" != /*/* ]]; then
      break
    fi
  done
}

lib() {
  local lib_path=
  find_lib $PWD
  if [[ "$lib_path" ]]; then
    echo "Found lib in $lib_path"
    cd $lib_path || return 1
  else
    echo "Couldn't find lib."
  fi
}

# inputs:
#   $1     var name of full path to file
#   $2     var name of colorized output var
colorize_path() {
  local -n _in=$1 _out=${2:-$1}
  local remaining=$_in
  _out=
  if [[ $colorize == t ]]; then
    local part color reset
    while [[ "$remaining" == /*/*/* ]]; do
      part=${remaining##*/}

      color= reset=
      if [[ -L "$remaining" ]]; then
        color=$CYAN
        reset=$RESET
      fi

      if [[ "${_out:-}" ]]; then
        _out="$color$part$reset/$_out"
      else
        _out="$color$part$reset"
      fi

      remaining=${remaining%/*}
    done

    if [[ "${_out:-}" ]]; then
      _out="$remaining/$_out"
    else
      _out="$remaining"
    fi

  else
    _out=$_in
  fi
}

# create a new cell
new() {
  local type name clean=f

  if [[ "${1:-}" == clean ]]; then
    clean=t
    shift
  fi

  type=${1:-} name=${2:-}

  show_usage() {
    echo "Usage: new [clean] {type} {name of new cell}" >&2
    echo "  will create a new cell based cell of the current directory." >&2
    echo "  if type=clone, will do a simple clone of the parent cell." >&2
    echo "  if type=up, will clone the cell and add the new cell as the upstream of the old cell." >&2
    echo "  if type=down, will clone the cell and add the old cell as the upstream of the new cell." >&2
    echo "  if type=validator, will clone the cell and add the new cell as a validator of the old cell." >&2
    echo "  name is the cell path of the new cell being created. Could include full work or seed path, or just path inside of the module." >&2
    echo "  if clean is specified, will delete any existing cell of the same name." >&2
    echo "  can use single letter abbreviations for type" >&2
  }

  case $type in
    c|clone)
      type=clone
    ;;
    u|up)
      type=up
    ;;
    d|down)
      type=down
    ;;
    v|validator)
      type=validator
    ;;
    ''|\?*|-h|--help)
      show_usage
      return 1
    ;;
    *)
      echo "Unknown clone type: $type" >&2
      return 1
    ;;
  esac

  if [[ ! "$name" ]]; then
    show_usage
    return 1
  fi

  local old_work_path=$PWD
  if [[ $old_work_path == /seed/* ]]; then
    old_work_path=/work${old_work_path#/seed}
  fi

  if [[ ! -e $old_work_path/.dna ]]; then
    echo "This command must be run within the parent cell to be cloned" >&2
    return 1
  fi

  local new_work_path=$name
  if [[ $name != /* ]]; then
    local parent_module=${old_work_path#/*/*/}
    parent_module=${old_work_path%$parent_module}
    new_work_path=$parent_module$name
  fi

  local new_seed_path=/seed/${new_work_path#/work/} \
    old_seed_path=/seed/${old_work_path#/work/} \

  while [[ ! -e $old_seed_path ]]; do
    old_seed_path=${old_seed_path%/*}
  done

  if [[ -e $new_seed_path ]]; then
    if [[ $clean == t ]]; then
      rm -rf $new_seed_path || return 1
    else
      echo "Seed already exists at $new_seed_path" >&2
      return 1
    fi
  fi

  mkdir -p $new_seed_path/.dna || return 1
  rsync -a $old_seed_path/.dna/ $new_seed_path/.dna/ || return 1

  if [[ $type == up || $type == validator ]]; then
    local up_name=${new_seed_path#/*/*/}
    up_name=${up_name//\//-}

    local target_folder=$old_seed_path/.dna/$type
    if [[ ! -e $target_folder ]]; then
      mkdir $target_folder || return 1
    fi

    local target=$target_folder/$up_name
    if [[ -e $target || -L $target ]]; then
      rm $target
    fi

    ln -s $new_work_path $target || return 1
  fi

  if [[ -e $new_work_path ]]; then
    if [[ $clean == t ]]; then
      rm -rf $new_work_path || return 1
    else
      echo "ERROR: new work path already exists: $new_work_path" >&2
      return 1
    fi
  fi

  local closest=$new_work_path
  while [[ ! -d $closest ]]; do
    closest=${closest%/*}
  done

  cd $closest || return 1

  plant || return 1

  cd $new_work_path || return 1

  if [[ $type == down ]]; then
    if [[ -d $new_seed_path/.dna/up ]]; then
      local u ups
      ups=$(find1 $new_seed_path/.dna/up) || return 1
      for u in $ups; do
        rm -rf $u || return 1
      done
    else
      mkdir $new_seed_path/.dna/up || return 1
    fi

    local up_name=${old_seed_path#/*/*/}
    up_name=${up_name//\//-}

    local target=$new_seed_path/.dna/up/$up_name
    if [[ -e $target ]]; then
      rm $target
    fi

    ln -s /work/${old_seed_path#/seed/} $target || return 1
  fi

  forge
}

# saves existing dir before changing to the given dir
cd() {

  local target=${1:-} old=$PWD
  if [[ ! "$target" ]]; then
    target=$HOME
  fi

  target=$(unrealpath "$target") || return 1
  if [[ -f "$target" || ! -e "$target" ]]; then
    echo "Directory doesn't exist: $target, trying parent" >&2
    target=${target%/*}
  fi

  if [[ ! -d "$target" ]]; then
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

CLEAR_SCREEN=$'\033[2J\r\033[H'
exec {fd_original_in}<&0
window() {
  local size=${1:-5} i line
  while true; do
    echo -n "$CLEAR_SCREEN"
    for ((i=0; i<size; i++)); do
      IFS= read line || break 2
      echo "$line"
      line=
    done
    read -u $fd_original_in -s -n 1 -p "-------- Press q to quit, any other key to continue --------" i
    if [[ $i == q ]]; then
      break
    fi
  done
  if [[ "${line:-}" ]]; then
    echo "$line"
  fi
}
#alias win=window

# inputs: 
#   $1  path to search for broken links
find_broken_links() {
  find -L "$(realpath $1)" -type l -print -o -name '.*' -prune
}

eval "printf -v hbar_equals '%.s=' {1..${COLUMNS:-40}}"

show_array() {
  local name=$1
  local -n _array=$name
  local i size char_array=f

  set +u
  size=${#_array[*]}
  set -u

  echo "$name size=$size"
  for i in "${!_array[@]}"; do
    if [[ ! -v _array[$i] ]]; then
      echo "$i: << MISSING >>"
    else
      echo "$i: ${_array[$i]:-}"
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

# git stuff
alias gc='git checkout'
alias gb='git branch -vv'
alias gs='git status -uno'
alias gsu='git status'
alias ga='git add'
alias gcb='git checkout -B'
alias gundo='git reset --hard && git clean -df'
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
localize() {
  local recursive=f
  case ${1:-} in
    -r)
      recursive=t
    ;;
  esac

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

gl() {
  git --no-pager log -n ${lines:-20} --decorate --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s" "$@"
}

gB() {
  git --no-pager log -n ${lines:-20} --simplify-by-decoration --all --date-order --decorate --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s" "$@"
}

gcm() {
  local message="$1"; shift
  if [ "$message" ]; then
      git commit -m "$message" "$@" || return 1
  else
      git commit || return 1
  fi
}

ifout() {
  awk 'BEGIN { rc=1 } length($0) > 0 { rc=0; print } END { exit rc }'
}

fql() {
  local return_code=0
  if [ "$*" ]; then
    find -L . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' -name "$@" 2>/dev/null | ifout || return_code=1
  elif [ "${depth:-}" ]; then
    find -L . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' -maxdepth $depth 2>/dev/null | ifout || return_code=1
  else
    find -L . -not -path '*/.git/*' -not -path '*/.idea/*' -not -path '*/.gradle/*' 2>/dev/null | ifout || return_code=1
  fi

  return $return_code
}

fq() {
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

fd() {
  find . -name '.?*' -prune -o -type d "$@" -print
}

fdepth() {
  local depth=$1; shift
  find . -mindepth $depth -maxdepth $depth -name "$@" 2>/dev/null | ifout 
}

ff() {
  local i
  for ((i = 1; i < 20; i++)); do
    echo "searching depth $i..."
    fdepth $i "$@"
    if [ "$?" != 0 ]; then
      echo -e "$MOVE_UP"
    fi
  done
}

grepr() {
  grep -D skip -n -s -r -I "$@" *
}

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
  cd_to_branch || return 1
  while true; do
    local members=( $(find1 . -type d -name "*:*" | sort -g) ) || return 1
    if [[ "${members:-}" ]]; then
      cd $members || return 1
    else
      break
    fi
  done
  return 0
}

cd_to_trunk() {
  cd_to_branch || return 1
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

cd_to_branch() {
  local d=$PWD last_cell=$PWD
  while [[ $d == */.dna* || $d == */.cyto* ]]; do
    d=${d%/*}
  done
  if [[ $d != $PWD ]]; then
    cd $d || return 1
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

branch() {
  cd_to_branch
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

cell_info() {
  local p=

  if [[ $PWD == /work/* || $PWD == /seed/* ]]; then
    local cell_name=$(realpath $PWD)
    cell_name=${cell_name#/*/*/}
    while [[ $cell_name == *:* || $cell_name == */.* ]]; do
      cell_name=${cell_name%/*:*}
      cell_name=${cell_name%/.*}
    done

    if [[ $PWD == /seed/* ]]; then
      p+="[seed "
    else
      if [[ $PWD == */.cyto || $PWD == */.cyto/* ]]; then
        p+="[cyto "
      elif [[ $PWD == */.dna || $PWD == */.dna/* ]]; then
        p+="[dna "
      else
        local sub_branches=( $(find1 . -name "*:*") ) || return 1
        if [[ "${sub_branches:-}" ]]; then
          if [[ $PWD =~ : ]]; then
            p+="[branch "
          else
            p+="[trunk "
          fi
        else
          if [[ $PWD =~ : ]]; then
            p+="[leaf "
          else
            p+="[trunk "
          fi
        fi
      fi
    fi
    p+="$cell_name] "
    echo "$p"
  fi
}

# could be overridden by other components
custom_prompt_status() {
  :
}

out_exec() {
  local p=( "$@" )
  echo '' "${p[@]}" >&2
  eval "${p[@]}"
}

# searches for anything which links to a given file/folder
find_links() {
  local from=$1 start_at=${start_at:-$PWD}
  local links=( $(find "$start_at" -mindepth 1 -type l 2>/dev/null) ) || return 1
  for link in "${links[@]}"; do
    target=$(readlink $link)
    if [[ "$target" == "$from" \
       || "$target" == "$from"/* \
       ]]; then
       echo $link
    fi
  done
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

  if [[ -e "$from" && ! -e "$to" && -d "${to%/*}" ]]; then
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

show_short_path() {
  local p=$PWD
  get_short_path $p
  echo -n "$short_path "
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
| $GREEN\$prompt_name $BLUE\d \A $DIM_RED\$(prompt_error_string)$DIM_YELLOW\$(pid_path)$DIM_CYAN\$(cell_info)$PURPLE\$(parse_git_branch 2>/dev/null)$YELLOW\$(show_short_path)$DIM_CYAN\$(custom_prompt_status 2>/dev/null)$RESET
| $ "
  export PS2='> '
  export PS4='+ '
}

medium_prompt() {
  if [ ! "$BASH" ]; then
    return 0
  fi

  export PS1="
| $GREEN\$prompt_name $DIM_RED\$(prompt_error_string)$DIM_CYAN\$(cell_info)$PURPLE\$(parse_git_branch 2>/dev/null)$YELLOW\$(show_short_path)$DIM_CYAN\$(custom_prompt_status 2>/dev/null)$RESET
| $ "
  export PS2='> '
  export PS4='+ '
}

small_prompt() {
  if [ ! "$BASH" ]; then
    return 0
  fi

  export PS1="$DIM_YELLOW\W $PURPLE\$(parse_git_branch 2>/dev/null)$RESET\\\$ "
}

gacp() {
  local message=$*;
  git add .;
  git commit -m "$message";
  git push
}

big_prompt

