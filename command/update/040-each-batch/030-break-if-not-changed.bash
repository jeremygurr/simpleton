break_if_not_changed() {
begin_function_flat

  if [[ "$batch_status_path" ]]; then
    get_needs_update $batch_status_path || fail
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
begin_function_flat

  if [[ ! -d $node_status_path
     || -e $node_status_path/outdated
     || ! -e $node_status_path/last-successful-update
     ]]; then
    needs_update=t
  else
    get_is_stale $node_status_path || fail
    if [[ $is_stale == t ]]; then
      needs_update=t
    fi
  fi

  if [[ $needs_update=t && ${prevalidate:-f} == t ]] && type check &>/dev/null; then
    check || fail
    if [[ "${status:-}" && "${status:-}" == good ]]; then
      needs_update=f
    elif [[ "${value:-}" && "${result:-}" == "${value:-}" ]]; then
      needs_update=f
    fi
  fi

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

