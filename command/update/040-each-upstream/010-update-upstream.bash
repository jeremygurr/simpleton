update_upstream() {
local required_freshness= fresh= default_freshness=
if [[ -f $upstream.prep ]]; then
  source $upstream.prep || return 1
  local f=${upstream##*/}
  f=${f//-/_}_prep
  if ! type -t $f >/dev/null; then
    fatal "Because $upstream.prep exists, a function called $f must be defined within that file"
    return 1
  fi
  $f || return 1
  setup_dep_defaults || return 1
fi

local needs_update dims leaf_dims
load_dims $cell/.dna/dim || return 1
leaf_dims=( ${dims[*]:-} )
get_needs_update $(realpath $upstream) || return 1

if [[ $needs_update == t ]]; then
  downstream_ref_path=$upstream
  execute_command_step "$(realpath $upstream)" || return 1
fi

return 0
}

