break_if_batch_fresh() {
begin_function_flat

  if [[ "$batch_status_path" ]]; then
    get_needs_update $batch_status_path || fail
    if [[ $needs_update == f ]]; then
      do_after=break
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
     || ! -e $node_status_path/update_succeeded
     || $node_status_path/update_requested -nt $node_status_path/update_started ]]; then
    needs_update=t
  else
    get_is_stale $node_status_path || fail
    if [[ $is_stale == t ]]; then
      needs_update=t
    fi
  fi

  if [[ $needs_update=t && ${prevalidate:-f} == t ]] && type batch_read_external &>/dev/null; then
    if [[ ! "${value:-}" ]]; then
      err "batch_read_external is defined, but value was not given, so we can't use it."
      fail1
    fi
    batch_read_external || fail
    if [[ "$result" == "$value" ]]; then
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
  if [[ ! "$fresh" || "$fresh" == inf ]]; then
    is_stale=f
  elif [[ $fresh != 0 ]]; then
    local fresh_seconds
    convert_to_seconds $fresh fresh_seconds || fail
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

