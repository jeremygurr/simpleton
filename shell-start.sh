echo "Executing shell-start.sh"

if [[ "${ADD_PATH:-}" ]]; then
  export PATH=$ADD_PATH:$PATH
fi

prompt_name=${prompt_name:-}
NL=$'\n'

alias sp='source /etc/profile'
alias ls='ls --color=auto'
alias l='ls --color=auto -l'
alias ll='ls --color=auto -la'
alias rmr='rm -rf'
alias u='cd ..'
alias uu='cd ../..'
alias uuu='cd ../../..'
alias vi=vim

to() {
local target=$1
if [[ ! "$target" ]]; then
  target=$PWD
fi
if [[ ! -d "$target" ]]; then
  echo "Error: target doesn't exist or is not a folder: $target" >&2
  return 1
fi
pushd "$target" >/dev/null || return 1
return 0
}

back() {
popd >/dev/null
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
}

# this unlinks a linked file by copying what it links to locally
unset localize
localize() {
for file in $* ; do
  dirOfFile=`dirname $file`
  fileName=`basename $file`
  cd "$dirOfFile"
  description=`file $fileName`
  target=`echo $description | grep "symbolic link" | sed "s/.*symbolic link to \(.*\)/\1/" | sed "s/'//g" | sed "s/\\\`//g"`
# echo "Target: $target"
  if [ ! -z "$target" ]; then
    rm "$fileName"
    cp -R -a -p "${target}" "${fileName}"
  else
    echo "$file is not a symbolic link."
  fi
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

deep() {
git fetch --unshallow
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
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

leaf() {
source $SIMPLETON_REPO/lib/post-bash
source $SIMPLETON_REPO/lib/cell-lib
cd_to_leaf
}

trunk() {
source $SIMPLETON_REPO/lib/post-bash
source $SIMPLETON_REPO/lib/cell-lib
cd_to_trunk
}

seed() {
source $SIMPLETON_REPO/lib/post-bash
source $SIMPLETON_REPO/lib/cell-lib
cd_to_seed
}

plant() {
source $SIMPLETON_REPO/lib/post-bash
source $SIMPLETON_REPO/lib/cell-lib
cd_to_plant
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
NO_COLOUR="\[\033[0m\]"
BLUE="\[\033[0;34m\]"
LIGHT_BLUE="\[\033[1;34m\]"
PURPLE="\[\033[0;35m\]"
LIGHT_PURPLE="\[\033[1;35m\]"
CYAN="\[\033[0;36m\]"
LIGHT_GREEN=$'\033[0;32m'

get_cell_location_string() {
  local p=
  if [[ $PWD == /work/* ]]; then

    if [[ $PWD == */.dna/sub/* ]]; then
      p+="[seed"
    else
      p+="[plant"
    fi

    if [[ -d .dna ]]; then
      p+=" cell"
    fi

    if [[ $PWD == */.dim/* ]]; then
      if [[ -d .dim ]]; then
        p+=" branch"
      else
        p+=" leaf"
      fi
    elif [[ -d .dim ]]; then
      p+=" trunk"
    fi

    local without_seed=${PWD##*/.dna/sub}
    if [[ $without_seed == */.dna/* ]]; then
      p+=" dna"
    elif [[ $PWD == */.cyto/* ]]; then
      p+=" cyto"
    fi

    if [[ $PWD == */up/* ]]; then
      p+=" up"
    elif [[ $PWD == */down/* ]]; then
      p+=" down"
    fi

    p+="] "
  fi
  cell_location_string=$p
}

# could be overridden by other components
custom_prompt_status() {
  get_cell_location_string
  echo -n "$cell_location_string "
}

# moves a file or folder and updates all links pointing to it
relink() {
local from=$(realpath $1) to=$(realpath $2)

if [[ ! -e "$from" ]]; then
  echo "ERROR: $from doesn't exist" >&2
  return 1
fi

if [[ -e "$to" ]]; then
  echo "ERROR: $to already exists" >&2
  return 1
fi

if [[ "$to" == */.dna/sub/* ]]; then
  local planted_to=${to//.dna\/sub\//}
  if [[ -e "$planted_to" ]]; then
    to=$planted_to
  fi
fi

local link target planted_from=${from//.dna\/sub\//}
for link in $(find "$current_folder" -mindepth 1 -type l); do
  if [[ ! -e $link ]]; then
    echo "Broken link: $link -> $(readlink $link). Fix this before proceeding." >&2
    return 1
  fi
  target=$(realpath $link)
  if [[ "$target" == "$from" \
     || "$target" == "$from"/* \
     || "$target" == "$planted_from" \
     || "$target" == "$planted_from"/* \
     ]]; then

    local sub_path=
    if [[ "$target" == "$from"/* ]]; then
      sub_path=${target#$from}
    elif [[ "$target" == "$planted_from"/* ]]; then
      sub_path=${target#$planted_from}
    fi

    set -x
    rm "$link" || return 1
    ln -s "$to$sub_path" "$link" || return 1
    set +x
  fi
done

set -x
mv "$from" "$to" || return 1
set +x

return 0
}

prompt_error_string() {
local rc=$?
[[ $rc > 0 ]] && echo -n "err $rc "
}

short_path() {
local p=$PWD
if [[ "$p" == /*/*/*/* ]]; then
  p=${PWD%/*/*/*}
  p=${PWD#$p/}
fi
echo -n "$p"
}

big_prompt() {
if [ ! "$BASH" ]; then
  return 0
fi

export PS1="
| $RED\$(prompt_error_string)$LIGHT_GREEN\$prompt_name $LIGHT_BLUE\d \A $CYAN\$(custom_prompt_status 2>/dev/null)$NO_COLOUR
| $LIGHT_RED\$(short_path) $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
export PS2='> '
export PS4='+ '
}

medium_prompt() {
export PS1="$LIGHT_GREEN\$prompt_name $LIGHT_RED\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
}

small_prompt() {
export PS1="$LIGHT_RED\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
}

big_prompt
