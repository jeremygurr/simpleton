lock_batch() {
current_batch_job_path=
if [[ "$batch_job_path" ]]; then
  current_batch_job_path=$batch_job_path/current
  folder_to_lock=$current_batch_job_path folder_lock || fail
  if [[ "$batch_log_path" ]]; then
    if [[ ! -d $batch_log_path ]]; then
      mkdir -p $batch_log_path || fail
    fi
    change_log_file $batch_log_path || fail
  fi
fi
}

