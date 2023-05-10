unlock_batch() {
if [[ "$batch_job_path" ]]; then
  folder_to_unlock=$current_batch_job_path folder_unlock || fail
  if [[ "$batch_log_path" ]]; then
    change_log_file - || fail
  fi
fi
}

