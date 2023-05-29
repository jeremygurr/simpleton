check_results() {

if [[ $update_successful == t ]]; then
  if [[ $post_validate == t ]]; then
    local status=good
    ignore_missing=t execute_op check || return 1
    if [[ $status == bad ]]; then
      update_successful=f
      can_retry=f
    fi
  fi
fi

if [[ "$status_path" ]]; then
  if [[ $update_successful == t ]]; then
    touch $status_path/last-good-update || return 1
  else
    touch $status_path/last-bad-update || return 1
  fi
fi

local log_message=
if [[ $update_successful == t ]]; then
  log_message="Update successful." || return 1
else
  log_message="Update failed." || return 1
fi

write_to_log debug update_result "$log_message" || return 1

}

