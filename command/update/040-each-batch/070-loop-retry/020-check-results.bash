check_results() {
if [[ $update_successful == t ]]; then
  if [[ "$post_validate" == t ]]; then
    local status=good
    ignore_missing=t execute_op check || return 1
    if [[ $status == bad ]]; then
      update_successful=f
      can_retry=f
    fi
  fi
  if [[ "$batch_status_path" ]]; then
    touch $batch_status_path/last-good-update || return 1
  fi
else
  if [[ "$batch_status_path" ]]; then
    touch $batch_status_path/last-bad-update || return 1
  fi
fi
}