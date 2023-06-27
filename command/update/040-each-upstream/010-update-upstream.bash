update_upstream() {
local required_freshness= fresh= default_freshness=

local log_vars=upstream 
begin_function

  if [[ "${localize_dim_vars:-}" ]]; then
    eval "$localize_dim_vars"
  fi

  prep_upstream $upstream || fail

  local needs_update
  get_needs_update $upstream || fail

  if [[ $needs_update == t ]]; then
    downstream_ref_path=$upstream
    downstream_cell_stack+=( $cell_path )
    fork execute_command "$(realpath $upstream)" update || fail
    if [[ "$update_successful" == f ]]; then
      error "Failed to update upstream cell $upstream"
    else 
      update_successful=
    fi
  fi

end_function
handle_return
}

