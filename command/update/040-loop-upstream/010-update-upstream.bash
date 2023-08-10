update_upstream() {
  local required_freshness=$required_freshness fresh=$fresh default_freshness=$default_freshness

  local log_show_vars=^upstream 
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

    debug_start
    local needs_update=
    local up_part=${upstream##*/}
    local up_cyto=$up_path/$up_part
    if [[ ! -d "$up_path" ]]; then
      mkdir "$up_path" || fail
    fi

    if [[ $previous_upstream_changed == t ]]; then
      log_debug "Previous upstream changed, removing cyto upstream"
      rm $up_cyto || fail
    fi

    if [[ ! -e $up_cyto ]]; then
      log_debug "Cyto upstream is missing, will create"
      setup_cyto_upstream $upstream $up_cyto || fail
    fi

    prep_upstream $up_cyto || fail
    get_needs_update $up_cyto || fail

    if [[ $needs_update == t ]]; then
      downstream_ref_path=$upstream
      downstream_cell_stack+=( $cell_path )
      fork execute_command "$(realpath $up_cyto)" update || fail
      previous_upstream_changed=t
      handle_upstream_result || fail
    fi

  end_function
  handle_return
}

