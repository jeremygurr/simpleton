#!/usr/bin/env bash

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
      if [[ -e $up_dna.prep && ! -e $up_cyto.prep ]]; then
        safe_link $up_dna.prep $up_cyto.prep || fail
      fi
      needs_update=t
    fi

    prep_upstream $up_cyto || fail

    if [[ ! "$needs_update" ]]; then
      get_needs_update $up_cyto || fail
    fi

    if [[ $needs_update == t ]]; then
      downstream_ref_path=$up_cyto \
        execute_command "$(realpath $up_dna)" update || fail

      previous_upstream_changed=t
      handle_upstream_result || fail
    fi

    write_lock=f \
      cell_lock $up_cyto || fail

  end_function
  handle_return
}

