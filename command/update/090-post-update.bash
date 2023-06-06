post_update() {
local result_string

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
      local freshness=$completion_time
      if [[ $cell_is_external == t ]]; then
        freshness=
      fi
      changed=$freshness \
        completion_time=$completion_time \
        from_cell=$cell_path \
        propogate_success_to_parents || return 1
      changed=$freshness \
        completion_time=$completion_time \
        from_cell=$cell_path \
        propogate_success_to_downstream || return 1
    else
      touch -d @$completion_time $status_path/last-bad-update-end || return 1
      cp -a $status_path/last-update-start \
            $status_path/last-bad-update-start || return 1
    fi
  fi
  info "Update $result_string."
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
