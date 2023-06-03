break_if_not_changed() {
begin_function_flat
  needs_update=t
  if [[ "$status_path" ]]; then
    get_needs_update || fail
  fi
  if [[ $needs_update == f ]]; then
    leave_loop=1
  fi
end_function_flat
handle_return
}

get_needs_update() {
needs_update=f
local log_message="No update needed"
begin_function_flat

  if [[ -v leaf_dims ]]; then
    needs_update=t
    log_message="Needs update because this cell has dimensions, and so individual dimensions must be checked for update"
  elif [[ ! -e $status_path/subs-up-to-date ]]; then
    needs_update=t
    log_message="Needs update because a sub cell is outdated"
  elif [[ ! -e $status_path/deps-up-to-date ]]; then
    needs_update=t
    log_message="Needs update because a dependency is outdated"
  elif [[ ! -e $status_path/last-good-update-start ]]; then
    needs_update=t
    log_message="Needs update because cell has never been updated successfully"
  else
    get_is_stale $status_path || fail
    if [[ $is_stale == t ]]; then
      needs_update=t
      log_message="Needs update because cell is stale"
    fi
  fi

  if [[ $needs_update=t && ${prevalidate:-f} == t ]] && type check &>/dev/null; then
    check || fail
    if [[ "${status:-}" && "${status:-}" == good ]]; then
      needs_update=f
      log_message="No update needed because remote value already matches intended value"
    elif [[ "${value:-}" && "${result:-}" == "${value:-}" ]]; then
      needs_update=f
      log_message="No update needed because remote value already matches intended value"
    fi
  fi

  if [[ $needs_update == t ]]; then
    action=update_check debug "$log_message"
  else
    action=update_check info "$log_message"
  fi

end_function_flat
handle_return
}

get_is_stale() {
begin_function_flat
  is_stale=t
  if [[ ! "$required_freshness" || "$required_freshness" == inf ]]; then
    is_stale=f
  elif [[ $required_freshness != 0 ]]; then
    local fresh_seconds
    convert_to_seconds $required_freshness fresh_seconds || fail
    local fresh_cutoff=$((EPOCHSECONDS-fresh_seconds)) \
      out_timestamp= freshness_file
    is_stale=f
    begin_for freshness_file in sub-freshness dep-freshness last-good-update-end; doo
      if [[ -f $status_path/$freshness_file ]]; then
        out_timestamp=$(date -r $status_path/freshness_file +%s)
      fi
      if [[ "$out_timestamp" && $out_timestamp -lt $fresh_cutoff ]]; then
        is_stale=t
      fi
    end_for
  fi
end_function_flat
handle_return
}

