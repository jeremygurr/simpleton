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
      touch $status_path/last-good-update || return 1
    else
      touch $status_path/last-bad-update || return 1
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
