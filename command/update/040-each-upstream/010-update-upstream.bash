update_upstream() {
if [[ -f $upstream.prep ]]; then
  source $upstream.prep || return 1
  local f=${upstream##*/}
  f=${f//-/_}_prep
  if ! type -t $f; then
    fatal "Because $upstream.prep exists, a function called $f must be defined within that file"
    return 1
  fi
  required_freshness=
  $f || return 1
  setup_dep_defaults || return 1
fi
get_node_needs_update $upstream || return 1
if [[ $needs_update == t ]]; then
  downstream_ref_path=$upstream
  execute_command_step "$(realpath $upstream)" || return 1
fi
return 0
}

