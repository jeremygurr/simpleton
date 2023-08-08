update_upstream() {
local required_freshness=$required_freshness fresh=$fresh default_freshness=$default_freshness

local log_vars=upstream 
begin_function

  if [[ "${localize_dim_vars:-}" ]]; then
    eval "$localize_dim_vars"
  fi

  # This may be overridden by upstream prep file to customize how failure of this upstream is handled
  handle_upstream_result() {
    if [[ "$update_successful" == f ]]; then
      log_error "Failed to update upstream cell $upstream"
    else 
      update_successful=
    fi
  }

  local needs_update=
  with_update=t \
    prep_upstream $upstream || fail

  get_needs_update $upstream || fail

  if [[ $needs_update == t ]]; then
    downstream_ref_path=$upstream
    downstream_cell_stack+=( $cell_path )
    fork execute_command "$(realpath $upstream)" update || fail
    handle_upstream_result || fail
  fi

end_function
handle_return
}

