update_upstream() {
local required_freshness= fresh= default_freshness=

if [[ "${localize_dim_vars:-}" ]]; then
  eval "$localize_dim_vars"
fi

prep_upstream $upstream || return 1

local needs_update
get_needs_update $upstream || return 1

if [[ $needs_update == t ]]; then
  downstream_ref_path=$upstream
  execute_command_step "$(realpath $upstream)" || return 1
fi

return 0
}

