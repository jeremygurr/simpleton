update_upstream() {
  local required_freshness=$required_freshness fresh=$fresh \
    default_freshness=$default_freshness up_dna=$upstream

  local log_show_vars=^up_dna 
  begin_function

    if [[ "${localize_dim_vars:-}" ]]; then
      eval "$localize_dim_vars"
    fi

    # This may be overridden by upstream prep file to customize how failure of this upstream is handled
    handle_upstream_result() {
      if [[ "$update_successful" == f ]]; then
        log_error "Failed to update upstream cell $up_dna"
      else 
        update_successful=
      fi
    }

    local needs_update=
    local up_part=${up_dna##*/}
    local up_cyto=$up_path/$up_part
    if [[ ! -d "$up_path" ]]; then
      mkdir "$up_path" || fail
    fi

    if [[ $previous_upstream_changed == t && -e "$up_cyto" ]]; then
      log_debug "Previous upstream changed, removing cyto upstream"
      rm $up_cyto || fail
    fi

    if [[ ! -e $up_cyto ]]; then
      log_debug "Cyto upstream is missing, will need to update"
      needs_update=t
    else
      prep_upstream $up_cyto || fail
      get_needs_update $up_cyto || fail
    fi

    if [[ $needs_update == t ]]; then
      # not used anywhere? 
      # downstream_cell_stack+=( $cell_path )

      # on_trunk gets set to false when the first dim being updated has more than one matching member, thus creating branches (not trunk anymore). 
      #   Used to determine what level of cell to link to cyto upstream
      on_trunk=t \
      downstream_ref_path=$up_cyto \
        fork execute_command "$(realpath $up_cyto)" update || fail

      previous_upstream_changed=t
      handle_upstream_result || fail
    fi

  end_function
  handle_return
}

