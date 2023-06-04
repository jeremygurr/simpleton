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
while true; do
  local last_part=${PWD##*/}
  if [[ -d .dim ]]; then
    cd .dim || return 1
  elif [[ "$last_part" == .dim ]]; then
    if [[ "${1:-}" && -d "$1" ]]; then
      cd "$1" || return 1
      shift || true
    else
      local files=( $(find -mindepth 1 -maxdepth 1 -type d -not -name ".*") )
      if [[ -d "$files/.dim" ]]; then
        cd $files/.dim || return 1
      elif [[ -d "$files/.dna" ]]; then
        cd $files || return 1
        break
      else
        break
      fi
    fi
  fi
done
return 0
}

trunk() {
while true; do
  local last=${PWD##*/}
  local parent=${PWD%/*}
  parent=${parent##*/}
  if [[ ${#PWD} -lt 2 ]]; then
    break
  fi
  if [[ "$last" == .dim || "$last" == .dna ]]; then
    cd .. || return 1
  elif [[ "$PWD" == */.dim/* ]]; then
    cd ${PWD%%/.dim/*} || return 1
  elif [[ "$PWD" == */.dna/* ]]; then
    cd ${PWD%%/.dna/*} || return 1
  else
    break
  fi
done
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

custom_prompt_status() {
  :
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

export PS1="| ${RED}\$(prompt_error_string)${LIGHT_GREEN}\$prompt_name$PURPLE\u $LIGHT_BLUE\d \A $CYAN\$(custom_prompt_status 2>/dev/null)$NO_COLOUR
| $LIGHT_RED\$(short_path) $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
export PS2='> '
export PS4='+ '
}

medium_prompt() {
export PS1="${LIGHT_GREEN}\$prompt_name$PURPLE\u $LIGHT_RED\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
}

small_prompt() {
export PS1="$LIGHT_RED\W $LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR\\\$ "
}

big_prompt
