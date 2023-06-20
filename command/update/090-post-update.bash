post_update() {
local result_string

completion_time=${completion_time:-$EPOCHSECONDS}
if [[ $update_successful == t ]]; then
  result_string="successful"
else
  result_string="failed"
fi

if [[ $pretend == f ]]; then
  if [[ "$status_path" ]]; then
    if [[ $update_successful == t ]]; then
      touch -d @$completion_time $status_path/last-good-update-end || return 1
      cp -a $status_path/last-update-start \
            $status_path/last-good-update-start || return 1
      if [[ $something_changed == t ]]; then
        debug_start
        from_cell=$cell_path \
          propagate_change_to_downstream || return 1
      fi
    else
      touch -d @$completion_time $status_path/last-bad-update-end || return 1
      cp -a $status_path/last-update-start \
            $status_path/last-bad-update-start || return 1
    fi
  fi

  if [[ $cell_is_leaf == t || $show_branches == t ]]; then
    info "Update $result_string."
  else
    debug "Update $result_string."
  fi

else
  info "Pretend update $result_string."
fi

if [[ "$job_path" ]]; then
  folder_to_unlock=$current_job_path folder_unlock || fail
fi
if [[ "$log_path" ]]; then
  change_log_file - || fail
fi

return 0
}
