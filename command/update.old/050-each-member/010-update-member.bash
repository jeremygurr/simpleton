update_member() {
  local sane_value member_path \
    log_vars=member log_show_vars=member \
    downstream_ref_path=${downstream_ref_path:-}

  begin_function_hi
    get_sane_value "$member" || fail
    member_path=$cell_path/.dim/$sane_value
    if [[ ! -d $member_path ]]; then
      if [[ ! -d $cell_path/.dim ]]; then
        mkdir $cell_path/.dim || fail
      fi
      create_sub_cell $member_path || fail
    fi
    local needs_update=
    get_needs_update $member_path || return 1
    if [[ $needs_update == t ]]; then

      if (( member_count > 1 )); then
        log_debug "More than one member found ($member_count), not passing downstream_ref_path."
        downstream_ref_path=
      elif [[ "$downstream_ref_path" ]]; then
        log_debug "Only one member found, passing downstream_ref_path: $downstream_ref_path"
      fi
      fork_fg execute_command $member_path update || fail

      if [[ $update_successful == f ]]; then
        error "Failed to update member cell $member"
        reply_to_caller "update_successful=f" || fail
      else 
        update_successful=
      fi
    fi
  end_function
  handle_return
}

