export SIMPLETON_HOME=/repo/simpleton
export PATH=$SIMPLETON_HOME/bin:$PATH

alias x=simpleton-execute
alias vi=vim
alias u='cd ..'

set -o vi
set +H
export SHELL="/bin/bash"
export LS_OPTIONS='--color=auto'
export EDITOR=vim

unset parse_git_branch
parse_git_branch() {
  local p=$PWD
  while [[ "$p" =~ / ]]; do
    if [ -d $p/.git ]; then
      local r=$(cat $p/.git/HEAD)
      if [[ "$r" =~ refs/heads ]]; then
        echo "$r" | sed -E 's/.*\/(.*)/ \[\1\]/'
      else
        git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \[\1\]/'
      fi
      break
    fi
    p=${p%/*}
  done
}

unset beautify_prompt
beautify_prompt() {
if [ ! "$BASH" ]; then
  return 0
fi
local RED="\[\033[0;31m\]"
local LIGHT_RED="\[\033[1;31m\]"
local NO_COLOUR="\[\033[0m\]"
local BLUE="\[\033[0;34m\]"
local LIGHT_BLUE="\[\033[1;34m\]"
local PURPLE="\[\033[0;35m\]"
local LIGHT_PURPLE="\[\033[1;35m\]"
local CYAN="\[\033[0;36m\]"
local LIGHT_GREEN=$'\033[0;32m'

#export PS1="${LIGHT_GREEN}simpleton: $LIGHT_BLUE\d \A $PURPLE\u $LIGHT_RED\W$LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR \\\$ "
export PS1="${LIGHT_GREEN}simpleton $PURPLE\u $LIGHT_RED\W$LIGHT_PURPLE\$(parse_git_branch 2>/dev/null)$NO_COLOUR \\\$ "
export PS2='> '
export PS4='+ '
}

beautify_prompt
