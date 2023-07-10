post_update() {
local result_string

begin_function_flat

  completion_time=${completion_time:-$EPOCHSECONDS}
  if [[ $update_successful == t ]]; then
    result_string="successful"
  else
    result_string="failed"
  fi

  if [[ $pretend == f ]]; then
    if [[ "$status_path" ]]; then
      if [[ $update_successful == t ]]; then
        touch -d @$completion_time $status_path/last-good-update-end || fail
        cp -a $status_path/last-update-start \
              $status_path/last-good-update-start || fail
        if [[ "${props:-}" ]]; then
          update_prop_hash || fail
        fi
        if [[ $something_changed == t ]]; then
          from_cell=$cell_path \
            propagate_change_to_downstream || fail
        fi
      else
        touch -d @$completion_time $status_path/last-bad-update-end || fail
        cp -a $status_path/last-update-start \
              $status_path/last-bad-update-start || fail
      fi
    fi

    if [[ $cell_is_leaf == t || $show_branches == t ]]; then
      log_info "Update $result_string. ($short_cell)"
    else
      log_debug "Update $result_string. ($short_cell)"
    fi

  else
    log_info "Pretend update $result_string."
  fi

  if [[ "${reply_file:-}" ]]; then
    echo "update_successful=${update_successful:-}" >>$reply_file || fail
  fi

  if [[ "$job_path" ]]; then
    folder_to_unlock=$current_job_path folder_unlock || fail
  fi
  if [[ "$log_path" ]]; then
    change_log_file - || fail
  fi

end_function_flat
handle_return
}
