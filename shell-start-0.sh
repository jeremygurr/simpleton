#!/usr/bin/env bash

SIMPLETON_LIB=/repo/simpleton/lib
source $SIMPLETON_LIB/lifted-bash || exit 1
source $SIMPLETON_LIB/bash-lib || exit 1
bash_lifted_init
source $SIMPLETON_LIB/walk-lib || exit 1

if [[ "${ADD_PATH:-}" ]]; then
  export PATH=$ADD_PATH:$PATH
fi

shopt -s extglob dotglob globstar huponexit
set +o histexpand

complete -r # remove built-in shell completion since it currently has problems

if [[ -e /tmp/prompt_name ]]; then
  prompt_name=$(</tmp/prompt_name)
  prompt_name=${prompt_name%%*( )}
fi

export prompt_name
NL=$'\n'

#export CHARSET=UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# cell aliases
alias get='cell get'
alias update='cell update'
alias upd='cell update'
alias clean='cell clean'
alias clean0='cell clean0'
alias clean1='cell clean1'
alias clean2='cell clean2'
alias status='cell status'
alias reactor='cell reactor'
alias plant='cell plant'
alias mock='cell mock'
alias dim='cell dim'
alias up='cell up'
alias ?='cell . ?'
alias ??='cell . ??'
alias safe='cell safe'
alias w=walk
alias f=forge

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

find_dna_work_cells() {
  local dir=$1 possibility only_one=${only_one:-f}
  local possibilities=$(find $dir/* -name ".*" -prune -o '(' -type l -print ')')
  for possibility in $possibilities; do
    local real=$(realpath $possibility) || return 1
    if [[ $real == /work/* && -e ${real%/*}/.dna ]]; then
      work_cells+=" $possibility,,,$real"
      if [[ $only_one == t ]]; then
        break
      fi
    elif [[ -d $real ]]; then
      find_dna_work_cells $possibility || return 1
    fi
  done
  return 0
}

get_short_path() {
  local p=$1
  local o=$p
  if [[ "$p" == */*/*/* ]]; then
    p=${p#/work/*/}
    p=${p#/seed/*/}
    o=$p
  fi
  if [[ "$p" == */*/*/*/* ]]; then
    p=${p%*/*/*/*/*}
    p=${o#$p/}
  fi
  short_path=$p
}

walk() {

  begin_function

    walk_init || fail
    local back_stack=()

    show_selection() {
      local extra= branches=() branch member \
        current_selection=$current_selection short_path
      get_short_path $current_selection
      echo "$HIGHLIGHT$hbar_equals$NL$short_path$RESET"

      while [[ $current_selection == *:* && $current_selection == /*/*/* ]]; do
        if [[ -f $current_selection/.member ]]; then
          member=" $(<$current_selection/.member)"
          if (( ${#member} > 60 )); then
            member="${member:0:60}..."
          fi
        else
          member=
        fi
        branch=${current_selection##*/}
        current_selection=${current_selection%/*}
        if [[ $branch == *:* ]]; then
          branches+=( "$branch$member" )
        fi
      done

      local i
      for (( i = ${#branches[*]} - 1; i >= 0; i-- )); do
        branch=${branches[$i]}
        echo "$branch"
      done
    }

    adjust_choices() {
      if [[ -d $current_selection/.. ]]; then
        hidden=f walk_add_choice "." "$current_selection/.." ".."
      fi

      if [[ "${back_stack:-}" ]]; then
        hidden=f walk_add_choice "b" "*back*" "back"
      fi

      local path
      if [[ -d $current_selection/.dna ]]; then
        if [[ $current_selection == *:* ]]; then
          path=${current_selection%%:*}
          path=${path%/*}
          walk_add_choice "t" "$path" "trunk"
        fi

        path=$current_selection/.dna
        local work_cells=
        only_one=t find_dna_work_cells $path
        if [[ "${work_cells}" ]]; then
          walk_add_choice "U" "$path" "dna upstream cells"
        fi

        path=$current_selection/.cyto/up-chosen
        if [[ -d $path ]]; then
          walk_add_choice "u" "$path" "upstream cells"
        else
          path=$current_selection/.dna/up
          if [[ -d $path ]]; then
            walk_add_choice "u" "$path" "upstream cells"
          fi
        fi

        path=$current_selection/.cyto/down
        if [[ -d $path ]]; then
          walk_add_choice "d" "$path" "downstream cells"
        fi

        walk_add_dirs $current_selection || return 1
      elif [[ ${current_selection##*/} == down ]]; then
        walk_add_dirs $current_selection || return 1
      elif [[ ${current_selection##*/} == up-chosen ]]; then
        walk_add_dirs $current_selection || return 1
      elif [[ ${current_selection##*/} == up ]]; then
        walk_add_dirs $current_selection || return 1
      elif [[ ${current_selection##*/} == .dna ]]; then
        local work_cells= work_cell pw possibility
        find_dna_work_cells $current_selection || return 1
        for pw in $work_cells; do
          possibility=${pw%,,,*}
          possibility=${possibility#$current_selection/}
          work_cell=${pw#*,,,}
          local short_cell=${work_cell#/work/*/}
          walk_add_choice_i "${work_cell%/*}" "$possibility -> ${short_cell}"
        done
      fi
      return 0
    }

    handle_walk_responses() {
      if [[ "$response" == "*back*" ]]; then
        current_selection=${back_stack[-1]}
        unset back_stack[-1]
      elif [[ -d "$response" ]]; then
        back_stack+=( "$current_selection" )
        current_selection="$(realpath $response)"
      fi
      walk_filter=
    }

    local result= current_selection=$(realpath .)

    if [[ $current_selection == /seed/* ]]; then
      current_selection=/work${current_selection#/seed}
    fi

    prompt="Choose (press enter to stop here): " walk_execute $current_selection || fail

    if [[ -d "$result" ]]; then
      cd $(realpath $result) || fail
    fi

  end_function
  handle_return

}

# used internally by jwalk
jwalk_update_type() {
  local query=$current_selection
  if [[ ! "$query" ]]; then
    query=.
  fi
  #current_type=$(jq -r "$query | type" "$json_file" 2>/dev/null)
  current_type=$(jq -r "$query | type" "$json_file")
  if [[ ! "$current_type" ]]; then
    current_type=unknown
  fi
}

# walk through json file
jwalk() {

  local json_file=${1:-}
  begin_function

    if [[ ! "${json_file:-}" || ! -e "$json_file" ]]; then
      echo "usage: jwalk {json file}" >&2
      fail1
    fi

    walk_init || fail
    local back_stack=()

    show_selection() {
      local current_selection=$current_selection 
      echo "$HIGHLIGHT$hbar_equals$NL$current_selection ($current_type)$RESET"
      if [[ "$current_type" != object && "$current_type" != array ]]; then
        jq -r "$current_selection" "$json_file"
      fi
    }

    adjust_choices() {
      if (( ${#back_stack[*]} > 0 )); then
        hidden=f walk_add_choice "b" "*back*" "back"
      fi

      local query type_query
      if [[ "$current_selection" ]]; then
        query="$current_selection | keys_unsorted | .[]"
        type_query="$current_selection | .[] | type"
      else
        query='keys_unsorted | .[]'
        type_query=".[] | type"
      fi

      local values= value OIFS=$IFS types= type message=
      IFS=$'\n' 
      values=( $(jq -r "$query" "$json_file" 2>/dev/null) )
      types=( $(jq -r "$type_query" "$json_file" 2>/dev/null) )
      IFS=$OIFS

      local i
      for (( i = 0; i < ${#values[*]}; i++ )); do
        value=${values[$i]}
        type=${types[$i]}
        message=
        if [[ "$type" != object && "$type" != array ]]; then
          if [[ $value =~ ^[0-9]+$ ]]; then
            query="$current_selection[$value]"
          else
            query="$current_selection.$value"
          fi
          message="$value ($(jq -r "$query" "$json_file" 2>/dev/null))"
        fi
        if [[ ! "$message" ]]; then
          message=$value
        fi
        if [[ ! "${walk_filter:-}" || "$message" == *"$walk_filter"* ]]; then
          walk_add_choice_i "$value" "$message"
        fi
      done

      if [[ "$current_type" == object || "$current_type" == array ]]; then
        hidden=f walk_add_choice "f" "*full*" "View full object at this location"
      fi

      return 0
    }

    handle_walk_responses() {
      if [[ "$response" == "*back*" ]]; then
        current_selection=${back_stack[-1]}
        jwalk_update_type
        unset back_stack[-1]
      elif [[ "$response" == "*full*" ]]; then
        jq -r "$current_selection" "$json_file"
      elif [[ "$response" =~ ^[0-9]+$ ]]; then
        back_stack+=( "$current_selection" )
        current_selection+="[$response]"
        jwalk_update_type
      elif [[ "$response" ]]; then
        back_stack+=( "$current_selection" )
        if [[ "$response" =~ ^[a-zA-Z_]+$ ]]; then
          current_selection+=".$response"
        else
          current_selection+="[\"$response\"]"
        fi
        jwalk_update_type
      else
        invalid_response=t
      fi
      walk_filter=
    }

    local result= current_selection= current_type
    jwalk_update_type

    prompt="Choose (press enter to stop here): " walk_execute "$current_selection" || fail

    if [[ "$result" ]]; then
      echo "Use this command to see the selected data:"
      echo "jq -r '$result' $json_file"
    fi

  end_function
  handle_return

}

# Edit a file in a cell
# if a dna file is edited, this will automatically clear the context files so they can be regenerated
edit() {
  local file=$1
  $EDITOR "$file" || return 1
  if [[ $file == */.dna/* ]]; then
    local cell=${file%%/.dna/*}
    rm $cell/.cyto/context* &>/dev/null
  fi
  return 0
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

forge_add_subs() {
  local base=$1 from=${2:-$1}
  begin_function_grip

    local file files short_path short_file colored_base
    colorize_path base colored_base
    get_short_path $colored_base
    files=$(find1 $from | sort -g)
    for file in $files; do
      colorize_path file short_file
      short_file=${short_file#$base/}

      if [[ ! "${walk_filter:-}" || "$short_path $short_file" == *"$walk_filter"* ]]; then
        if [[ -d $file ]]; then
          short_file+=/
        fi

        local wi=$walk_index
        if [[ $wi != ? ]]; then
          wi=/
        fi
        walk_add_choice "$walk_index" "$current_action $file" "$short_path $wi $current_action $short_file"
        (( walk_index++ ))
      fi

      if [[ -d $file
         && ( ! -L $file || ! -d $file/.dna ) 
         ]]; then

        if [[ ! -L $file || $link_expansion == t ]]; then
          if [[ ${file##*/} == .dna || ${file##*/} == .root ]]; then
            forge_add_subs $file
          else
            forge_add_subs $base $file
          fi
        fi

      fi

    done
  end_function
  handle_return
}
 
forge_add_roots() {
  local path=$1
  begin_function_grip

    if [[ $path == /*/*/* ]]; then
      forge_add_roots ${path%/*}
    fi

    if [[ -d $path/.root ]]; then
      forge_add_subs $path/.root
    fi

  end_function
  handle_return
}

forge() {
  local colorize=${colorize:-t}
  begin_function

    walk_init || fail
    local back_stack=() \
      current_action=edit \
      link_expansion=f \
      add_roots=f \

    show_selection() {
      local extra= branches=() branch member \
        current_selection=$current_selection short_path
      get_short_path ${current_selection#/seed/*/}
      echo "$HIGHLIGHT$hbar_equals$NL$short_path$RESET"

      while [[ $current_selection == *:* && $current_selection == /*/*/* ]]; do
        if [[ -f $current_selection/.member ]]; then
          member=" $(<$current_selection/.member)"
          if (( ${#member} > 60 )); then
            member="${member:0:60}..."
          fi
        else
          member=
        fi
        branch=${current_selection##*/}
        current_selection=${current_selection%/*}
        if [[ $branch == *:* ]]; then
          branches+=( "$branch$member" )
        fi
      done

      local i
      for (( i = ${#branches[*]} - 1; i >= 0; i-- )); do
        branch=${branches[$i]}
        echo "$branch"
      done
    }

    adjust_choices() {
      if [[ -d $current_selection/.. ]]; then
        hidden=t walk_add_choice "." "$current_selection/.." "cd .."
      fi

      hidden=t walk_add_choice "a" "*action*" "- Change action"
      hidden=t walk_add_choice "b" "*back*" "- Go back to previous directory"
      hidden=t walk_add_choice "d" "*new-dir*" "- Create a new directory here"
      hidden=t walk_add_choice "f" "*new-file*" "- Create a new file here"
      hidden=t walk_add_choice "j" "*jump*" "- Go to other jump point"
      hidden=t walk_add_choice "J" "*jump-set*" "- Set current jump point to this location"
      hidden=t walk_add_choice "r" "*real*" "- Go to real (not linked) path of the current directory"
      hidden=t walk_add_choice "R" "*roots*" "- Toggle whether to include roots"
      hidden=t walk_add_choice "t" "*target*" "- Set target for move/copy/link commands"
      hidden=t walk_add_choice "x" "*expand*" "- Toggle link expansion"

      local path
      #if [[ -d $current_selection/.dna ]]; then
      #  if [[ $current_selection == *:* ]]; then
      #    path=${current_selection%%:*}
      #    path=${path%/*}
      #    walk_add_choice "t" "$path" "trunk"
      #  fi
      #fi

      if [[ $add_roots == t ]]; then
        forge_add_roots ${current_selection%/*} || fail
      fi
      forge_add_subs $current_selection || fail

      #display_prefix='. ' \
      #walk_add_dirs $current_selection

      return 0
    }

    handle_walk_responses() {
      if [[ "$response" == "*back*" ]]; then
        current_selection=${back_stack[-1]}
        unset back_stack[-1]
      elif [[ "$response" == "*new-dir*" ]]; then
        local new_name
        read -p "Name of new directory: " new_name
        if [[ "${new_name:-}" ]]; then
          mkdir "$current_selection/$new_name"
        fi
      elif [[ "$response" == "*new-file*" ]]; then
        local new_name
        read -p "Name of new file: " new_name
        if [[ "${new_name:-}" ]]; then
          edit "$current_selection/$new_name"
        fi
      elif [[ "$response" == "*expand*" ]]; then
        if [[ $link_expansion == f ]]; then
          link_expansion=t
        else
          link_expansion=f
        fi
      elif [[ "$response" == "*jump*" ]]; then
        if [[ "${walk_jump_other:-}" ]]; then
          current_selection=$walk_jump_other
        fi
        local o=$walk_jump_other
        walk_jump_other=$walk_jump_current
        walk_jump_current=$o
      elif [[ "$response" == "*jump-set*" ]]; then
        walk_jump_current=$current_selection
      elif [[ "$response" == "*real*" ]]; then
        back_stack+=( $current_selection )
        current_selection=$(realpath $current_selection)
      elif [[ "$response" == "*roots*" ]]; then
        if [[ $add_roots == t ]]; then
          add_roots=f
        else
          add_roots=t
        fi
      elif [[ "$response" == "*target*" ]]; then
        echo "Setting target of copy/move/link commands to $current_selection"
        action_target=$current_selection
      elif [[ "$response" == *action* ]]; then
        local choice
        while true; do

          echo "c copy item to target dir (use t command to set destination)"
          echo "C copy contents of item to target dir (use t command to set destination)"
          echo "d delete"
          echo "D duplicate"
          echo "e edit"
          echo "i info"
          echo "g go"
          echo "l link to target dir (use t command to set destination)"
          echo "m move to target dir (use t command to set destination)"
          echo "q cancel action change"
          echo "r rename"
          echo "v view file"

          read -n1 -sp "Choose action: " choice
          case "$choice" in
            c)
              echo "copy"
              current_action=copy
              break
            ;;
            C)
              echo "copy-contents"
              current_action=copy-contents
              break
            ;;
            d)
              echo "delete"
              current_action=delete
              break
            ;;
            D)
              echo "duplicate"
              current_action=duplicate
              break
            ;;
            e)
              echo "edit"
              current_action=edit
              break
            ;;
            i)
              echo "info"
              current_action=info
              break
            ;;
            g)
              echo "go"
              current_action=go
              break
            ;;
            l)
              echo "link"
              current_action=link
              break
            ;;
            m)
              echo "move"
              current_action=move
              break
            ;;
            q)
              echo "abort"
              break
            ;;
            r)
              echo "rename"
              current_action=rename
              break
            ;;
            v)
              echo "view"
              current_action=view
              break
            ;;
            *)
              echo "Invalid action"
            ;; 
          esac
        done
      elif [[ "$response" == *" "* ]]; then
        read action target <<<$response
        case $action in
          copy)
            if [[ "${action_target:-}" ]]; then
              echo rsync -av $target $action_target/
              #pause
              rsync -av $target $action_target/
            else
              echo "No target has been set. Go to the target dir and use the 't' command to set the target."
            fi
          ;;
          copy-contents)
            if [[ "${action_target:-}" ]]; then
              echo rsync -av $target/ $action_target/
              #pause
              rsync -av $target/ $action_target/
            else
              echo "No target has been set. Go to the target dir and use the 't' command to set the target."
            fi
          ;;
          delete)
            rm -rf "$target"
            #recursive=t remove_empty_parents ${target%/*}
          ;;
          duplicate)
            local new_name=
            read -p "New name: (leave empty to cancel) " new_name 
            if [[ "$new_name" ]]; then
              if [[ -d $target ]]; then
                echo rsync -av $target/ ${target%/*}/$new_name/
                rsync -av $target/ ${target%/*}/$new_name/
              else
                echo rsync -av $target ${target%/*}/$new_name
                rsync -av $target ${target%/*}/$new_name
              fi
            fi
          ;;
          edit)
            edit "$target"
          ;;
          go)
            back_stack+=( $current_selection )
            if [[ -f $target ]]; then
              target=${target%/*}
            fi
            current_selection=$target
            walk_filter=
          ;;
          rename)
            local new_name=
            read -p "New name: (leave empty to cancel) " new_name 
            if [[ "$new_name" ]]; then
              mv $target ${target%/*}/$new_name
            fi
          ;;
          view)
            echo "Viewing $target"
            echo "$HIGHLIGHT$hbar_equals$RESET"
            if [[ -f $target ]]; then
              cat "$target"
            else
              ls -la "$target"
              if [[ -L "$target" ]]; then
                ls -la "$target/"
              fi
            fi
            echo "$HIGHLIGHT$hbar_equals$RESET"
            pause
          ;;
          *)
            echo "ERROR: unknown action: $action." >&2
            return 1
          ;; 
        esac
      elif [[ -d "$response" ]]; then
        current_selection=$(unrealpath $response)
        walk_filter=
      fi
    }

    local result= current_selection=$PWD \
      walk_jump_current=$PWD walk_jump_other=$PWD

    if [[ $current_selection != /seed/* ]]; then
      current_selection=/seed${current_selection#/work}
      while [[ ! -d $current_selection && $current_selection == /*/*/* ]]; do
        current_selection=${current_selection%/*}
      done
      if [[ ! -d $current_selection ]]; then
        echo "Current folder is invalid" >&2
        return 1
      fi
    fi

    prompt="Choose (press enter to stop here): " \
      clear_screen=f \
      column_alignment=4 \
      walk_execute $current_selection || fail

    if [[ -d "$result" ]]; then
      local target=$(realpath $result)
      target=/work/${target#/seed/}
      while [[ ! -d $target ]]; do
        target=${target%/*}
      done
      cd $target || fail
    fi

  end_function
  handle_return
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
    echo "  if type=up, will clone the cell and add the child cell as the upstream of the parent." >&2
    echo "  if type=down, will clone the cell and add the parent cell as the upstream of the child." >&2
    echo "  name is the cell path of the new cell being created. Could include full work path, or just path inside of the module." >&2
    echo "  if clean is specified, will delete any existing cell of the same name." >&2
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
    \?*|-h|--help)
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

  if [[ $type == up ]]; then
    local up_name=${new_seed_path#/*/*/}
    up_name=${up_name//\//-}

    local target=$old_seed_path/.dna/up/$up_name
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
alias wi=window

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

alias f1='find . -maxdepth 1 -not -path "*/.git*"'
alias f2='find . -maxdepth 2 -not -path "*/.git*"'
alias f3='find . -maxdepth 3 -not -path "*/.git*"'
alias f4='find . -maxdepth 4 -not -path "*/.git*"'

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

big_prompt

