break_if_not_changed() {
begin_function_flat

  if [[ "$status_path" ]]; then
    get_needs_update $status_path || fail
    if [[ $needs_update == f ]]; then
      leave_loop=1
    fi
  fi

end_function_flat
handle_return
}

get_needs_update() {
local -r node_status_path=$1
needs_update=f
local log_message="No update needed"
begin_function_flat

  if [[ ! -d $node_status_path ]]; then
    needs_update=t
    log_message="Needs update because status path doesn't exist"
  elif [[ -e $node_status_path/outdated ]]; then
    needs_update=t
    log_message="Needs update because cell is outdated"
  elif [[ ! -e $node_status_path/last-good-update ]]; then
    needs_update=t
    log_message="Needs update because cell has never been updated"
  else
    get_is_stale $node_status_path || fail
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

  write_to_log debug update_check "$log_message"

end_function_flat
handle_return
}

get_is_stale() {
begin_function_flat
  local -r node_status_path=$1
  is_stale=t
  if [[ ! "$required_freshness" || "$required_freshness" == inf ]]; then
    is_stale=f
  elif [[ $required_freshness != 0 ]]; then
    local fresh_seconds
    convert_to_seconds $required_freshness fresh_seconds || fail
    local fresh_cutoff=$((EPOCHSECONDS-fresh_seconds))
    local out_timestamp=
    if [[ -f $node_status_path/oldest-update ]]; then
      out_timestamp=$(date -r $node_status_path/freshness +%s)
    fi
    if [[ "$out_timestamp" && $out_timestamp -ge $fresh_cutoff ]]; then
      is_stale=f
    fi
  fi
end_function_flat
handle_return
}

