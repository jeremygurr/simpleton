unlock_batch() {
if [[ "$batch_job_path" ]]; then
  if [[ "$batch_status_path" ]]; then
    if [[ $update_successful == t ]]; then
      touch $batch_status_path/last-good-update || fail
      [[ -f $batch_status_path/outdated ]] && rm $batch_status_path/outdated
    else
      touch $batch_status_path/last-bad-update || fail
    fi
  fi
  folder_to_unlock=$current_batch_job_path folder_unlock || fail
  if [[ "$batch_log_path" ]]; then
    change_log_file - || fail
  fi
fi
}

